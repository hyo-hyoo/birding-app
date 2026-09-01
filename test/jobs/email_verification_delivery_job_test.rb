require "test_helper"
require_relative "../support/verification_test_support"

class EmailVerificationDeliveryJobTest < ActiveJob::TestCase
  include VerificationTestSupport

  setup do
    ActionMailer::Base.deliveries.clear
    clear_enqueued_jobs
  end

  test "rechecks current state then delivers outside the transaction in the requested locale" do
    user = create_user
    result = EmailVerificationIssuer.issue(user_id: user.id, locale: :"zh-CN")
    arguments = enqueued_jobs.last.fetch(:args)

    assert_no_difference -> { user.email_verification_tokens.count } do
      EmailVerificationDeliveryJob.perform_now(*arguments)
    end

    message = ActionMailer::Base.deliveries.sole
    assert_equal [ user.email_address ], message.to
    assert_equal "确认你的观鸟观察册邮箱", message.subject
    assert_includes message.text_part.body.to_s, "15 分钟"
    assert_includes message.text_part.body.to_s, "/email-verification?token="
    assert_equal result.token_id, user.email_verification_tokens.where(active_slot: 1).sole.id
  end

  test "exits without delivery for superseded consumed expired or verified state" do
    %i[superseded consumed expired verified].each do |state|
      user = create_user
      result = EmailVerificationIssuer.issue(user_id: user.id, locale: :ja)
      arguments = enqueued_jobs.last.fetch(:args)
      token = user.email_verification_tokens.find(result.token_id)
      now = Time.current
      case state
      when :superseded
        token.update!(active_slot: nil, invalidated_at: now, invalidation_reason: "superseded")
      when :consumed
        token.update!(active_slot: nil, invalidated_at: now, invalidation_reason: "consumed")
      when :expired
        # Time is advanced only while the worker runs; the immutable expiry stays unchanged.
      when :verified
        user.update!(email_verified_at: now)
      end

      assert_no_difference -> { ActionMailer::Base.deliveries.size }, state do
        if state == :expired
          travel 1.second { EmailVerificationDeliveryJob.perform_now(*arguments) }
        else
          EmailVerificationDeliveryJob.perform_now(*arguments)
        end
      end
    end
  end

  test "exits for deleted state and payload or scalar argument tampering" do
    user = create_user
    result = EmailVerificationIssuer.issue(user_id: user.id, locale: :ja)
    arguments = enqueued_jobs.last.fetch(:args)

    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      EmailVerificationDeliveryJob.perform_now(arguments[0], arguments[1], "zh-CN", arguments[3])
      EmailVerificationDeliveryJob.perform_now(arguments[0], arguments[1], arguments[2], "#{arguments[3]}x")
      user.email_verification_tokens.find(result.token_id).delete
      EmailVerificationDeliveryJob.perform_now(*arguments)
    end
  end

  test "job and mail logs contain neither raw token payload nor recipient" do
    user = create_user
    captured = StringIO.new
    previous_logger = ActiveJob::Base.logger
    ActiveJob::Base.logger = ActiveSupport::Logger.new(captured)
    ActionMailer::Base.logger = ActiveJob::Base.logger

    EmailVerificationIssuer.issue(user_id: user.id, locale: :ja)
    arguments = enqueued_jobs.last.fetch(:args)
    payload = EmailVerificationDeliveryPayload.load(arguments[3])
    EmailVerificationDeliveryJob.perform_now(*arguments)

    output = captured.string
    assert_not_includes output, payload.secret
    assert_not_includes output, arguments[3]
    assert_not_includes output, user.email_address
  ensure
    ActiveJob::Base.logger = previous_logger
    ActionMailer::Base.logger = previous_logger
  end

  test "delivery exception is sanitized and scheduled for a bounded retry" do
    user = create_user
    EmailVerificationIssuer.issue(user_id: user.id, locale: :ja)
    arguments = enqueued_jobs.last.fetch(:args)
    clear_enqueued_jobs
    captured = StringIO.new
    previous_logger = ActiveJob::Base.logger
    ActiveJob::Base.logger = ActiveSupport::Logger.new(captured)
    ActionMailer::Base.logger = ActiveJob::Base.logger
    delivery = Object.new
    def delivery.deliver_now = raise("secret smtp detail")

    attempts = 0
    message = Object.new
    message.define_singleton_method(:verification) do
      attempts += 1
      delivery
    end
    with_singleton_method(EmailVerificationMailer, :with, ->(*) { message }) do
      EmailVerificationDeliveryJob.perform_now(*arguments)
      first_retry = EmailVerificationDeliveryJob.deserialize(enqueued_jobs.shift)
      first_retry.perform_now
      final_retry = EmailVerificationDeliveryJob.deserialize(enqueued_jobs.shift)
      assert_raises(EmailVerificationDeliveryJob::DeliveryError) do
        final_retry.perform_now
      end
    end

    assert_equal 3, attempts
    assert_empty enqueued_jobs
    assert_not_includes captured.string, "secret smtp detail"
    assert_includes captured.string, "Verification email delivery failed"
  ensure
    ActiveJob::Base.logger = previous_logger
    ActionMailer::Base.logger = previous_logger
  end
end
