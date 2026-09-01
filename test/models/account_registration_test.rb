require "test_helper"
require_relative "../support/verification_test_support"

class AccountRegistrationTest < PersistentVerificationTestCase
  include ActiveJob::TestHelper
  include VerificationTestSupport

  setup { clear_enqueued_jobs }

  test "commits an unverified account initial admission token and job without a session" do
    email = "register-#{SecureRandom.hex(8)}@example.test"
    email_subject(email)

    result = AccountRegistration.register(
      email_address: "  #{email.upcase} ", password: AccountTestSupport::PASSWORD,
      password_confirmation: AccountTestSupport::PASSWORD, locale: :"zh-CN"
    )
    @users << result.user if result.user.persisted?

    assert_equal :created_email_queued, result.status
    assert result.user.persisted?
    assert_equal email, result.user.email_address
    assert_not result.user.email_verified?
    assert_empty result.user.sessions
    assert_equal 1, result.user.email_verification_tokens.where(active_slot: 1).count
    subject = VerificationRateLimitKey.subject("email", email)
    attempt = VerificationRateLimitKey.find_by!(subject).verification_send_attempts.sole
    assert_equal "initial", attempt.kind
    assert attempt.rate_limit_passed?
    assert_enqueued_jobs 1, only: EmailVerificationDeliveryJob
  end

  test "invalid registration keeps no account admission token or job" do
    email = "invalid-#{SecureRandom.hex(8)}@example.test"
    email_subject(email)

    result = AccountRegistration.register(
      email_address: "  #{email.upcase} ", password: "short", password_confirmation: "different", locale: :ja
    )

    assert_equal :invalid, result.status
    assert_not result.user.persisted?
    assert_equal email, result.user.email_address
    assert_nil User.find_by(email_address: email)
    assert_nil VerificationRateLimitKey.find_by(VerificationRateLimitKey.subject("email", email))
    assert_no_enqueued_jobs
  end

  test "duplicate registration creates no account admission or automatic resend" do
    user = tracked_user
    email_subject(user.email_address)

    result = AccountRegistration.register(
      email_address: user.email_address.upcase, password: AccountTestSupport::PASSWORD,
      password_confirmation: AccountTestSupport::PASSWORD, locale: :ja
    )

    assert_equal :invalid, result.status
    assert result.user.errors.of_kind?(:email_address, :taken)
    assert_equal 1, User.where(email_address: user.email_address).count
    assert_empty user.email_verification_tokens
    assert_nil VerificationRateLimitKey.find_by(VerificationRateLimitKey.subject("email", user.email_address))
    assert_no_enqueued_jobs
  end

  test "keeps the new account and committed admission when enqueue fails" do
    email = "enqueue-fail-#{SecureRandom.hex(8)}@example.test"
    email_subject(email)

    result = with_singleton_method(EmailVerificationDeliveryJob, :perform_later, ->(*) { false }) do
      AccountRegistration.register(
        email_address: email, password: AccountTestSupport::PASSWORD,
        password_confirmation: AccountTestSupport::PASSWORD, locale: :ja
      )
    end
    @users << result.user if result.user.persisted?

    assert_equal :created_email_unavailable, result.status
    assert result.user.reload.persisted?
    assert_not result.user.email_verified?
    assert_empty result.user.email_verification_tokens
    attempt = VerificationRateLimitKey.find_by!(VerificationRateLimitKey.subject("email", email)).verification_send_attempts.sole
    assert_equal "initial", attempt.kind
    assert attempt.rate_limit_passed?
    assert_empty result.user.sessions
  end
end
