require "test_helper"
require_relative "../support/verification_test_support"

class EmailVerificationRequestTest < PersistentVerificationTestCase
  include ActiveJob::TestHelper
  include VerificationTestSupport

  setup { clear_enqueued_jobs }

  test "unknown verified and unverified email use the same public accepted result" do
    unverified = tracked_user
    verified = tracked_user(email_verified_at: Time.current)
    unknown = "unknown-#{SecureRandom.hex(8)}@example.test"
    email_subject(unverified.email_address)
    ip_subject("192.0.2.11")
    email_subject(verified.email_address)
    ip_subject("192.0.2.12")
    email_subject(unknown)
    ip_subject("192.0.2.13")

    results = [
      EmailVerificationRequest.resend(email_address: unverified.email_address, ip_address: "192.0.2.11", locale: :ja),
      EmailVerificationRequest.resend(email_address: verified.email_address, ip_address: "192.0.2.12", locale: :ja),
      EmailVerificationRequest.resend(email_address: unknown, ip_address: "192.0.2.13", locale: :ja)
    ]

    assert_equal [ :accepted, :accepted, :accepted ], results
    assert_equal 1, unverified.email_verification_tokens.where(active_slot: 1).count
    assert_empty verified.email_verification_tokens
    assert_equal 1, enqueued_jobs.count { |job| job[:job] == EmailVerificationDeliveryJob }
    [ unverified.email_address, verified.email_address, unknown ].each do |email|
      attempt = VerificationRateLimitKey.find_by!(VerificationRateLimitKey.subject("email", email)).verification_send_attempts.sole
      assert_equal "resend", attempt.kind
      assert attempt.rate_limit_passed?
    end
  end

  test "invalid email rate limit and admission outage return account-independent statuses" do
    ip_subject("192.0.2.20")
    assert_equal :invalid_email,
      EmailVerificationRequest.resend(email_address: "bad", ip_address: "192.0.2.20", locale: :ja)

    email = "limited-#{SecureRandom.hex(8)}@example.test"
    email_subject(email)
    ip_subject("192.0.2.21")
    ip_subject("192.0.2.22")
    assert_equal :accepted,
      EmailVerificationRequest.resend(email_address: email, ip_address: "192.0.2.21", locale: :ja)
    assert_equal :rate_limited,
      EmailVerificationRequest.resend(email_address: email, ip_address: "192.0.2.22", locale: :ja)

    with_singleton_method(VerificationRateLimiter, :resend, ->(**) { raise VerificationRateLimiter::AdmissionUnavailable }) do
      assert_equal :temporarily_unavailable,
        EmailVerificationRequest.resend(email_address: email, ip_address: "192.0.2.23", locale: :ja)
    end
  end

  test "enqueue failure does not change the accepted resend response or restore an older accounting meaning" do
    user = tracked_user
    email_subject(user.email_address)
    ip_subject("192.0.2.30")

    result = with_singleton_method(EmailVerificationDeliveryJob, :perform_later, ->(*) { false }) do
      EmailVerificationRequest.resend(email_address: user.email_address, ip_address: "192.0.2.30", locale: :ja)
    end

    assert_equal :accepted, result
    assert_empty user.email_verification_tokens
    attempt = VerificationRateLimitKey.find_by!(VerificationRateLimitKey.subject("email", user.email_address)).verification_send_attempts.sole
    assert attempt.rate_limit_passed?
  end
end
