class EmailVerificationDeliveryJob < ApplicationJob
  class DeliveryError < StandardError; end

  self.enqueue_after_transaction_commit = false
  self.log_arguments = false
  queue_as :mailers
  retry_on DeliveryError, wait: 5.seconds, attempts: 3

  def perform(user_id, token_id, locale, encrypted_payload)
    payload = EmailVerificationDeliveryPayload.load(encrypted_payload)
    return unless matching_arguments?(payload, user_id, token_id, locale)

    delivery = current_delivery(user_id, token_id, payload.secret)
    return unless delivery

    message = EmailVerificationMailer.with(
      email_address: delivery.fetch(:email_address),
      secret: payload.secret,
      locale: locale
    ).verification
    silently { message.deliver_now }
  rescue StandardError => error
    raise if error.is_a?(DeliveryError)

    raise DeliveryError, "Verification email delivery failed", cause: nil
  end

  private
    def matching_arguments?(payload, user_id, token_id, locale)
      payload && payload.user_id == user_id && payload.token_id == token_id && payload.locale == locale &&
        I18n.available_locales.map(&:to_s).include?(locale)
    end

    def current_delivery(user_id, token_id, secret)
      User.transaction do
        user = User.lock.find_by(id: user_id)
        next unless user && !user.email_verified?

        token = user.email_verification_tokens.lock.find_by(id: token_id)
        now = Time.current
        next unless token && token.active_slot == 1 && token.invalidated_at.nil? &&
          token.invalidation_reason.nil? && token.expires_at > now &&
          ActiveSupport::SecurityUtils.secure_compare(token.token_digest, EmailVerificationToken.digest_for(secret))

        { email_address: user.email_address.dup }
      end
    end

    def silently(&block)
      logger = ActionMailer::Base.logger
      logger ? logger.silence(&block) : yield
    rescue StandardError
      raise DeliveryError, "Verification email delivery failed", cause: nil
    end
end
