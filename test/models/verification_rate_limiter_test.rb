require "test_helper"
require_relative "../support/verification_test_support"

class VerificationRateLimiterTest < PersistentVerificationTestCase
  test "unknown unverified and verified accounts use identical admission and accounting" do
    unknown = @email
    unverified = tracked_user
    verified = tracked_user(email_verified_at: Time.current)
    [ unknown, unverified.email_address, verified.email_address ].each_with_index do |email, index|
      ip = "2001:db8::#{index + 10}"
      assert_equal :allowed, resend(email: email, ip: ip)
      assert_equal :rate_limited, resend(email: email, ip: ip)
      key = VerificationRateLimitKey.find_by!(email_subject(email))
      assert_equal [ true, false ], key.verification_send_attempts.order(:id).pluck(:rate_limit_passed)
    end
    assert_equal 0, EmailVerificationToken.where(user: [ unverified, verified ]).count
  end

  test "normalization shares email and equivalent IP identities and never stores plaintext" do
    assert_equal :allowed, resend(email: " A.B+Bird#{@email} ", ip: "::ffff:192.0.2.11")
    assert_equal :rate_limited, resend(email: "a.b+bird#{@email}", ip: "192.0.2.11")
    assert_equal VerificationRateLimitKey.subject("ip", "192.0.2.11"), ip_subject("::ffff:192.0.2.11")
    subject = email_subject
    assert_match(/\A[0-9a-f]{64}\z/, subject[:subject_digest])
    assert_not_equal Digest::SHA256.hexdigest(@email), subject[:subject_digest]
    assert_not_equal subject[:subject_digest], VerificationRateLimitKey.subject("ip", @email)[:subject_digest]
    assert_not_includes VerificationRateLimitKey.column_names, "email_address"
    assert_not_includes VerificationRateLimitKey.column_names, "ip_address"
    assert_equal %w[created_at id kind rate_limit_passed verification_rate_limit_key_id], VerificationSendAttempt.column_names.sort
  end

  test "cooldown is exactly 60 seconds and rejected attempts do not extend it" do
    travel_to Time.utc(2026, 8, 31, 12) do
      assert_equal :allowed, resend
      travel 59.seconds
      assert_equal :rate_limited, resend
      travel 1.second
      assert_equal :allowed, resend
    end
  end

  test "three resend attempts includes rejected attempts even without any prior admission" do
    travel_to Time.utc(2026, 8, 31, 12) do
      3.times { |index| seed_attempt(email_subject, at: Time.current - (index + 1).minutes, passed: false) }
      assert_equal :rate_limited, resend
      key = VerificationRateLimitKey.find_by!(email_subject)
      assert_equal 4, key.verification_send_attempts.count
    end
  end

  test "15 minute window excludes its lower boundary and includes recent attempts" do
    travel_to Time.utc(2026, 8, 31, 12) do
      seed_attempt(email_subject, at: 15.minutes.ago, passed: false)
      2.times { |index| seed_attempt(email_subject, at: Time.current - (index + 1).minutes, passed: false) }
      assert_equal :allowed, resend
      assert_equal :rate_limited, resend(ip: "192.0.2.12")
    end
  end

  test "IP budget spans different email identities and includes rejected attempts" do
    10.times do |index|
      assert_equal :allowed, resend(email: "#{index}-#{@email}")
    end
    assert_equal :rate_limited, resend(email: "last-#{@email}")
    assert_equal 11, VerificationRateLimitKey.find_by!(ip_subject).verification_send_attempts.count
  end

  test "initial admission contributes cooldown but not resend quota" do
    travel_to Time.utc(2026, 8, 31, 12) do
      email_subject
      assert_equal :allowed, VerificationRateLimiter.initial(email_address: @email)
      assert_equal :rate_limited, resend
      travel 60.seconds
      assert_equal :allowed, resend
      travel 60.seconds
      assert_equal :allowed, resend
      travel 60.seconds
      assert_equal :rate_limited, resend
      attempts = VerificationRateLimitKey.find_by!(email_subject).verification_send_attempts
      assert_equal 1, attempts.where(kind: "initial").count
      assert_equal 4, attempts.where(kind: "resend").count
    end
  end

  test "invalid emails count only against IP and cannot create fake email subjects" do
    assert_equal :invalid_email, resend(email: "not-an-email")
    key = VerificationRateLimitKey.find_by!(ip_subject)
    assert_equal 1, key.verification_send_attempts.count
    assert key.verification_send_attempts.sole.rate_limit_passed?
    assert_nil VerificationRateLimitKey.find_by(VerificationRateLimitKey.subject("email", "not-an-email"))
  end

  test "admission is independently committed and cannot hide in an outer transaction" do
    assert_equal :allowed, resend
    User.transaction { raise ActiveRecord::Rollback }
    assert VerificationRateLimitKey.find_by!(email_subject).verification_send_attempts.sole.rate_limit_passed?
    assert_raises(ArgumentError) do
      User.transaction { resend(email: "other-#{@email}") }
    end
  end

  test "invalid server IP fails closed without storing an address" do
    [ nil, [], "not-ip", "192.0.2.1/24" ].each do |ip|
      error = assert_raises(ArgumentError) { VerificationRateLimiter.resend(email_address: @email, ip_address: ip) }
      assert_equal "A valid server-resolved IP address is required", error.message
    end
  end

  test "no account lookup occurs and SQL logs filter subject digests" do
    stream = StringIO.new
    original_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = ActiveSupport::Logger.new(stream)
    statements = []
    subscriber = ->(*event) { statements << event.last[:sql] }
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { 2.times { resend } }
    assert_not statements.any? { |sql| sql.match?(/(?:FROM|JOIN) [`"]?users/i) }
    assert_not_includes stream.string, @email
    assert_not_includes stream.string, @ip
    assert_not stream.string.include?(email_subject[:subject_digest]), "Email digest must not appear in SQL logs"
    assert_not stream.string.include?(ip_subject[:subject_digest]), "IP digest must not appear in SQL logs"
    ActiveRecord::Base.connection.execute("SELECT 123 AS ordinary_sql_log_probe")
    assert_includes stream.string, "ordinary_sql_log_probe", "Privacy scope must not globally disable SQL logging"
  ensure
    ActiveRecord::Base.logger = original_logger
  end
end
