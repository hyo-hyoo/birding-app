class EmailVerificationIssuer
  EnqueueFailed = Class.new(StandardError)
  Result = Data.define(:status, :token_id)

  def self.issue(user_id:, locale:)
    User.transaction do
      user = User.lock.find_by(id: user_id)
      next Result.new(status: :ineligible, token_id: nil) unless user && !user.email_verified?

      now = Time.current
      user.email_verification_tokens.lock.where(active_slot: 1).to_a.each do |token|
        token.update!(active_slot: nil, invalidated_at: now, invalidation_reason: "superseded")
      end

      secret = EmailVerificationToken.generate_secret
      token = user.email_verification_tokens.create!(
        token_digest: EmailVerificationToken.digest_for(secret),
        active_slot: 1
      )
      normalized_locale = normalize_locale(locale)
      payload = EmailVerificationDeliveryPayload.dump(
        secret: secret,
        user_id: user.id,
        token_id: token.id,
        locale: normalized_locale,
        expires_at: token.expires_at
      )

      job = enqueue(user.id, token.id, normalized_locale, payload)
      unless job && job.successfully_enqueued? && job.enqueue_error.nil?
        failure = job.respond_to?(:enqueue_error) ? job.enqueue_error&.class&.name : nil
        failure ||= "AdapterRejected"
        Rails.logger.error("Verification enqueue failed (#{failure})")
        raise EnqueueFailed
      end

      Result.new(status: :queued, token_id: token.id)
    end
  rescue EnqueueFailed
    Result.new(status: :enqueue_failed, token_id: nil)
  end

  private_class_method def self.normalize_locale(locale)
    candidate = locale.to_s
    I18n.available_locales.map(&:to_s).include?(candidate) ? candidate : I18n.default_locale.to_s
  end

  private_class_method def self.enqueue(user_id, token_id, locale, payload)
    logger = ActiveJob::Base.logger
    if logger
      logger.silence { EmailVerificationDeliveryJob.perform_later(user_id, token_id, locale, payload) }
    else
      EmailVerificationDeliveryJob.perform_later(user_id, token_id, locale, payload)
    end
  rescue StandardError => error
    Rails.logger.error("Verification enqueue failed (#{error.class.name})")
    raise EnqueueFailed, cause: nil
  end
end
