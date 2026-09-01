require_relative "account_test_support"
require "timeout"

module VerificationTestSupport
  include AccountTestSupport

  def with_singleton_method(target, name, replacement)
    singleton = target.singleton_class
    original = target.method(name)
    singleton.define_method(name, replacement)
    yield
  ensure
    singleton.define_method(name, original)
  end

  # A committed, already-issued token fixture. Actual issuance/enqueue is M2-B.
  def token_for(user)
    secret = EmailVerificationToken.generate_secret
    token = EmailVerificationToken.create!(user: user, token_digest: EmailVerificationToken.digest_for(secret), active_slot: 1)
    [ token, secret ]
  end
end

class PersistentVerificationTestCase < ActiveSupport::TestCase
  include VerificationTestSupport
  self.use_transactional_tests = false

  setup do
    @subjects, @users, @threads, @gates = [], [], [], []
    @email = "m2-#{SecureRandom.hex(10)}@example.test"
    @ip = "2001:db8:#{SecureRandom.hex(2)}:#{SecureRandom.hex(2)}::1"
  end

  teardown do
    @gates.each { |queue| 4.times { queue << true } }
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
      @subjects.uniq.each do |subject|
        if key = VerificationRateLimitKey.find_by(subject)
          VerificationSendAttempt.where(verification_rate_limit_key_id: key.id).delete_all
          key.delete
        end
      end
      ids = @users.map(&:id)
      EmailVerificationToken.where(user_id: ids).delete_all
      Session.where(user_id: ids).delete_all
      User.where(id: ids).delete_all
    end
    raise failures.first if failures.any?
  end

  private
    def tracked_user(**attributes)
      create_user(**attributes).tap { |user| @users << user }
    end

    def email_subject(email = @email)
      VerificationRateLimitKey.subject("email", User.normalize_value_for(:email_address, email)).tap { |subject| @subjects << subject }
    end

    def ip_subject(ip = @ip)
      VerificationRateLimitKey.subject("ip", IPAddr.new(ip).native.to_s).tap { |subject| @subjects << subject }
    end

    def resend(email: @email, ip: @ip)
      normalized = email.is_a?(String) ? User.normalize_value_for(:email_address, email) : ""
      email_subject(email) if normalized.length <= 255 && URI::MailTo::EMAIL_REGEXP.match?(normalized)
      ip_subject(ip)
      VerificationRateLimiter.resend(email_address: email, ip_address: ip)
    end

    def seed_attempt(subject, at:, passed:, kind: "resend")
      key = VerificationRateLimitKey.create_or_find_by!(subject)
      key.verification_send_attempts.create!(created_at: at, rate_limit_passed: passed, kind: kind)
    end

    def gate
      Queue.new.tap { |queue| @gates << queue }
    end

    def await(queue)
      Timeout.timeout(10) { queue.pop }
    end

    def async(&block)
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          original = connection.select_value("SELECT @@SESSION.innodb_lock_wait_timeout").to_i
          connection.execute("SET SESSION innodb_lock_wait_timeout = 5")
          block.call
        ensure
          connection.execute("SET SESSION innodb_lock_wait_timeout = #{original}") if original
        end
      end.tap { |thread| @threads << thread }
    end

    def concurrently(*operations)
      ready = Queue.new
      start = gate
      workers = operations.map do |operation|
        async do
          ready << ActiveRecord::Base.connection.select_value("SELECT CONNECTION_ID()")
          await(start)
          operation.call
        end
      end
      assert_equal operations.size, operations.size.times.map { await(ready) }.uniq.size
      operations.size.times { start << true }
      workers.map(&:value)
    end
end
