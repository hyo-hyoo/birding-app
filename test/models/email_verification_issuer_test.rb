require "test_helper"
require_relative "../support/verification_test_support"

class EmailVerificationIssuerTest < PersistentVerificationTestCase
  include ActiveJob::TestHelper
  include VerificationTestSupport

  setup do
    clear_enqueued_jobs
    ActionMailer::Base.deliveries.clear
  end

  test "supersedes the old token only after the new delivery job is actually enqueued" do
    user = tracked_user
    old_token, old_secret = token_for(user)

    result = nil
    assert_enqueued_with(job: EmailVerificationDeliveryJob) do
      result = EmailVerificationIssuer.issue(user_id: user.id, locale: :ja)
    end

    assert_equal :queued, result.status
    old_token.reload
    assert_nil old_token.active_slot
    assert_equal "superseded", old_token.invalidation_reason
    assert_equal :superseded, EmailVerificationToken.check(old_secret).status
    new_token = user.email_verification_tokens.find(result.token_id)
    assert_equal 1, new_token.active_slot
    assert_equal 1, user.email_verification_tokens.where(active_slot: 1).count
  end

  test "rolls back a new token and preserves the old link for every enqueue failure shape" do
    failures = [
      ->(*) { false },
      ->(*) { Struct.new(:enqueue_error) { def successfully_enqueued? = false }.new(ActiveJob::EnqueueError.new) },
      ->(*) { raise ActiveJob::EnqueueError }
    ]

    failures.each do |failure|
      user = tracked_user
      old_token, old_secret = token_for(user)
      result = with_singleton_method(EmailVerificationDeliveryJob, :perform_later, failure) do
        EmailVerificationIssuer.issue(user_id: user.id, locale: :ja)
      end

      assert_equal :enqueue_failed, result.status
      assert_equal :valid, EmailVerificationToken.check(old_secret).status
      assert_equal 1, old_token.reload.active_slot
      assert_equal [ old_token.id ], user.email_verification_tokens.reload.pluck(:id)
    end
  end

  test "does not issue for a missing or already verified user" do
    verified = tracked_user(email_verified_at: Time.current)

    assert_no_enqueued_jobs do
      assert_equal :ineligible, EmailVerificationIssuer.issue(user_id: verified.id, locale: :ja).status
      assert_equal :ineligible, EmailVerificationIssuer.issue(user_id: -1, locale: :ja).status
    end
    assert_empty verified.email_verification_tokens
  end

  test "falls back to the configured locale before encrypting and enqueuing" do
    user = tracked_user

    EmailVerificationIssuer.issue(user_id: user.id, locale: :en)
    arguments = enqueued_jobs.last.fetch(:args)
    payload = EmailVerificationDeliveryPayload.load(arguments.fetch(3))

    assert_equal I18n.default_locale.to_s, arguments.fetch(2)
    assert_equal I18n.default_locale.to_s, payload.locale
  end
end
