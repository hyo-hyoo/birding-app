require "test_helper"
require_relative "../support/verification_test_support"

class VerificationConcurrencyTest < PersistentVerificationTestCase
  test "concurrent confirmation consumes one token once and creates no Session" do
    user = tracked_user
    token, secret = token_for(user)
    results = concurrently(-> { EmailVerificationToken.confirm(secret).status }, -> { EmailVerificationToken.confirm(secret).status })
    assert_equal [ :consumed, :verified ], results.sort
    assert user.reload.email_verified?
    assert_equal "consumed", token.reload.invalidation_reason
    assert_empty user.sessions
  end

  test "failure after User update rolls back verification and token consumption" do
    user = tracked_user
    token, secret = token_for(user)
    subscriber = ->(*event) do
      raise "Injected token write failure" if event.last[:sql].match?(/UPDATE [`"]email_verification_tokens/)
    end
    error = assert_raises(RuntimeError, ActiveRecord::StatementInvalid) do
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { EmailVerificationToken.confirm(secret) }
    end
    assert_match(/Injected token write failure/, error.message)
    assert_not user.reload.email_verified?
    assert_equal 1, token.reload.active_slot
    assert_nil token.invalidated_at
    assert_equal :valid, EmailVerificationToken.check(secret).status
  end

  test "concurrent resend on the same new email key allows only one within 60 seconds" do
    results = concurrently(-> { resend(ip: "192.0.2.51") }, -> { resend(ip: "192.0.2.52") })
    assert_equal [ :allowed, :rate_limited ], results.sort
    key = VerificationRateLimitKey.find_by!(email_subject)
    assert_equal 1, VerificationRateLimitKey.where(email_subject).count
    assert_equal [ true, false ], key.verification_send_attempts.order(:id).pluck(:rate_limit_passed)
  end

  test "concurrent resend cannot bypass three denied email attempts with no cooldown" do
    3.times { |index| seed_attempt(email_subject, at: Time.current - (index + 1).minutes, passed: false) }
    results = concurrently(-> { resend(ip: "192.0.2.61") }, -> { resend(ip: "192.0.2.62") })
    assert_equal [ :rate_limited, :rate_limited ], results
    assert_equal 5, VerificationRateLimitKey.find_by!(email_subject).verification_send_attempts.count
  end

  test "concurrent requests sharing an IP cannot exceed its tenth attempt" do
    9.times { |index| seed_attempt(ip_subject, at: Time.current - (index + 1).seconds, passed: false) }
    results = concurrently(-> { resend(email: "one-#{@email}") }, -> { resend(email: "two-#{@email}") })
    assert_equal [ :allowed, :rate_limited ], results.sort
    attempts = VerificationRateLimitKey.find_by!(ip_subject).verification_send_attempts
    assert_equal 11, attempts.count
    assert_equal 1, attempts.where(rate_limit_passed: true).count
  end

  test "failure writing the second dimension rolls back both attempt rows" do
    email_subject
    ip_subject
    writes = 0
    subscriber = ->(*event) do
      if event.last[:sql].match?(/INSERT INTO [`"]verification_send_attempts/)
        writes += 1
        raise "Injected second dimension failure" if writes == 2
      end
    end
    error = assert_raises(RuntimeError, ActiveRecord::StatementInvalid) do
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { resend }
    end
    assert_match(/Injected second dimension failure/, error.message)
    @subjects.each do |subject|
      key = VerificationRateLimitKey.find_by(subject)
      assert key.nil? || key.verification_send_attempts.empty?
    end
  end

  test "retry rolls back earlier writes and records each dimension exactly once" do
    writes = 0
    subscriber = ->(*event) do
      if event.last[:sql].match?(/INSERT INTO [`"]verification_send_attempts/)
        writes += 1
        raise ActiveRecord::Deadlocked, "Injected deadlock" if writes <= 2
      end
    end
    result = ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { resend }
    assert_equal :allowed, result
    assert_equal 4, writes
    @subjects.uniq.each do |subject|
      attempts = VerificationRateLimitKey.find_by!(subject).verification_send_attempts
      assert_equal 1, attempts.count
      assert attempts.sole.rate_limit_passed?
    end
  end

  test "retry exhaustion fails closed after three attempts without leaking SQL" do
    writes = 0
    digest = email_subject[:subject_digest]
    stream = StringIO.new
    original_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = ActiveSupport::Logger.new(stream)
    subscriber = ->(*event) do
      if event.last[:sql].match?(/INSERT INTO [`"]verification_send_attempts/)
        writes += 1
        raise ActiveRecord::Deadlocked, "Injected sensitive SQL #{digest}"
      end
    end
    error = assert_raises(VerificationRateLimiter::AdmissionUnavailable) do
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { resend }
    end
    assert_equal 3, writes
    assert_nil error.cause
    assert_not error.message.include?(digest)
    assert_not stream.string.include?(digest), "Retry error must not log a subject digest"
    assert_includes stream.string, "ActiveRecord::Deadlocked"
    @subjects.uniq.each { |subject| assert_nil VerificationRateLimitKey.find_by(subject) }
  ensure
    ActiveRecord::Base.logger = original_logger
  end

  test "confirmation checks expiry after waiting for the User lock" do
    travel_to Time.utc(2026, 8, 31, 12) do
      user = tracked_user
      token, secret = token_for(user)
      before_lock = Queue.new
      proceed = gate
      worker = nil
      user.with_lock do
        worker = async do
          pause_before_lock_sql("users", before_lock, proceed) { EmailVerificationToken.confirm(secret) }
        end
        await(before_lock)
        travel 15.minutes
        proceed << true
      end
      assert_equal :expired, worker.value.status
      assert_not user.reload.email_verified?
      assert_nil token.reload.invalidated_at
    end
  end

  test "cooldown time is taken after acquiring rate-limit locks" do
    travel_to Time.utc(2026, 8, 31, 12) do
      assert_equal :allowed, resend
      travel 59.seconds
      key = VerificationRateLimitKey.find_by!(email_subject)
      before_lock = Queue.new
      proceed = gate
      worker = nil
      key.with_lock do
        worker = async do
          pause_before_lock_sql("verification_rate_limit_keys", before_lock, proceed) { resend }
        end
        await(before_lock)
        travel 1.second
        proceed << true
      end
      assert_equal :allowed, worker.value
      assert_equal 2, key.verification_send_attempts.where(rate_limit_passed: true).count
    end
  end

  private
    def pause_before_lock_sql(table, ready, proceed)
      paused = false
      trace = TracePoint.new(:call) do |event|
        if !paused && event.method_id == :log && event.binding.local_variable_defined?(:sql)
          sql = event.binding.local_variable_get(:sql)
          if sql.is_a?(String) && sql.include?("`#{table}`") && sql.include?("FOR UPDATE")
            paused = true
            ready << true
            await(proceed)
          end
        end
      end
      trace.enable(target_thread: Thread.current) { yield }
    end
end
