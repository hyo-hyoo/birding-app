require "test_helper"
require "timeout"
require_relative "../support/account_test_support"

class AuthenticationConcurrencyTest < ActiveSupport::TestCase
  include AccountTestSupport
  self.use_transactional_tests = false

  setup do
    @threads = []
    @gates = []
    @email = "m1-race-#{SecureRandom.hex(10)}@example.test"
    @user = create_user(email_address: @email, email_verified_at: Time.current)
  end

  teardown do
    @gates.each { |gate| 2.times { gate << true } }
    failures = []
    begin
      @threads.each do |thread|
        unless thread.join(10)
          thread.kill.join
          failures << Minitest::Assertion.new("Concurrent worker did not finish")
        end
      rescue StandardError => error
        failures << error
      end
    ensure
      ids = User.where(email_address: @email).pluck(:id)
      Session.where(user_id: ids).delete_all
      User.where(id: ids).delete_all
    end
    raise failures.first if failures.any?
  end

  test "real login authenticates before FOR UPDATE and inserts only after the lock" do
    events = []
    test_thread = Thread.current
    subscriber = ->(*event) do
      if Thread.current == test_thread
        sql = event.last[:sql]
        events << :lock if sql.match?(/SELECT.*[`"]users[`"].*FOR UPDATE/)
        events << :insert if sql.match?(/INSERT INTO [`"]?sessions/)
      end
    end
    trace = TracePoint.new(:return) do |event|
      events << :authenticate if event.self.is_a?(User) && event.callee_id == :authenticate
    end
    result = ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      trace.enable(target_thread: Thread.current) { login(@user) }
    end
    assert_equal :authenticated, result.status
    assert_equal [ :authenticate, :lock, :insert ], events
  end

  test "password reset committing after authentication but before User lock rejects old credentials" do
    authenticated = Queue.new
    continue_login = gate
    login(@user)
    worker = async do
      trace = TracePoint.new(:return) do |event|
        if event.self.is_a?(User) && event.callee_id == :authenticate
          authenticated << { transaction: User.connection_pool.active_connection?.transaction_open? }
          await(continue_login)
        end
      end
      trace.enable(target_thread: Thread.current) { login(@user) }
    end
    assert_equal false, await(authenticated).fetch(:transaction), "bcrypt must finish outside the login transaction"
    change_password_and_revoke_sessions
    continue_login << true
    result = worker.value
    assert_equal :invalid_credentials, result.status
    assert_nil result.session
    assert_empty @user.sessions.reload
  end

  test "login committing first is subsequently revoked by concurrent password reset" do
    inserted = Queue.new
    continue_login = gate
    login_worker = async do
      login_thread = Thread.current
      subscriber = ->(*event) do
        payload = event.last
        if Thread.current == login_thread && payload[:sql].match?(/INSERT INTO [`"]?sessions/)
          inserted << true
          await(continue_login)
        end
      end
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { login(@user) }
    end
    await(inserted)
    reset_started = Queue.new
    reset_worker = async do
      reset_started << true
      change_password_and_revoke_sessions
    end
    await(reset_started)
    continue_login << true
    result = login_worker.value
    reset_worker.value
    assert_equal :authenticated, result.status
    assert_not Session.exists?(result.session.id)
    assert_empty @user.sessions.reload
    assert_equal :invalid_credentials, login(@user).status
  end

  test "verification eligibility is read again after the authentication boundary" do
    authenticated = Queue.new
    continue_login = gate
    worker = async do
      trace = TracePoint.new(:return) do |event|
        if event.self.is_a?(User) && event.callee_id == :authenticate
          authenticated << true
          await(continue_login)
        end
      end
      trace.enable(target_thread: Thread.current) { login(@user) }
    end
    await(authenticated)
    @user.with_lock { @user.update!(email_verified_at: nil) }
    continue_login << true
    assert_equal :unverified, worker.value.status
    assert_empty @user.sessions.reload
  end

  test "two validated registrations racing cannot commit duplicate normalized email" do
    @user.destroy!
    candidates = [ build_user(email_address: @email.upcase), build_user(email_address: " #{@email} ") ]
    assert candidates.all?(&:valid?)
    ready = Queue.new
    start = gate
    workers = candidates.map do |candidate|
      async do
        ready << ActiveRecord::Base.connection.select_value("SELECT CONNECTION_ID()")
        await(start)
        candidate.save!(validate: false)
        :created
      rescue ActiveRecord::RecordNotUnique
        :duplicate
      end
    end
    assert_equal 2, 2.times.map { await(ready) }.uniq.size
    2.times { start << true }
    assert_equal [ :created, :duplicate ], workers.map(&:value).sort
    assert_equal 1, User.where(email_address: @email).count
  end

  private
    def gate
      Queue.new.tap { |queue| @gates << queue }
    end

    def await(queue)
      Timeout.timeout(10) { queue.pop }
    end

    def async(&block)
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          original_timeout = connection.select_value("SELECT @@SESSION.innodb_lock_wait_timeout").to_i
          connection.execute("SET SESSION innodb_lock_wait_timeout = 5")
          block.call
        ensure
          connection.execute("SET SESSION innodb_lock_wait_timeout = #{original_timeout}") if original_timeout
        end
      end.tap { |thread| @threads << thread }
    end

    # Simulation of the approved M5 atomic write protocol, not a password-reset API.
    def change_password_and_revoke_sessions
      digest = User.new(password: "NewBird123").password_digest
      User.transaction do
        user = User.lock.find(@user.id)
        user.update!(password_digest: digest)
        # CollectionProxy#delete_all otherwise follows the association's nullify
        # default; revocation must DELETE, never null a required owner FK.
        user.sessions.delete_all(:delete_all)
      end
    end
end
