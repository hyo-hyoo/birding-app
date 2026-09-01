class EmailVerificationDeliveryPayload
  PURPOSE = "birding-app/email-verification-delivery/v1"
  Value = Data.define(:secret, :user_id, :token_id, :locale)

  def self.dump(secret:, user_id:, token_id:, locale:, expires_at:)
    encryptor.encrypt_and_sign(
      { "secret" => secret, "user_id" => user_id, "token_id" => token_id, "locale" => locale.to_s },
      expires_at: expires_at,
      purpose: PURPOSE
    )
  end

  def self.load(payload)
    attributes = encryptor.decrypt_and_verify(payload, purpose: PURPOSE)
    return unless attributes.is_a?(Hash)

    value = Value.new(
      secret: attributes["secret"],
      user_id: attributes["user_id"],
      token_id: attributes["token_id"],
      locale: attributes["locale"]
    )
    value if valid?(value)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage, TypeError
    nil
  end

  private_class_method def self.valid?(value)
    value.user_id.is_a?(Integer) && value.token_id.is_a?(Integer) &&
      I18n.available_locales.map(&:to_s).include?(value.locale) &&
      EmailVerificationToken.digest_for(value.secret).present?
  end

  private_class_method def self.encryptor
    key = Rails.application.key_generator.generate_key(PURPOSE, ActiveSupport::MessageEncryptor.key_len)
    ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm", serializer: JSON)
  end
end
