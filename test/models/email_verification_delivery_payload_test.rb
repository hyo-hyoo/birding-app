require "test_helper"
require_relative "../support/verification_test_support"

class EmailVerificationDeliveryPayloadTest < ActiveSupport::TestCase
  include VerificationTestSupport

  test "encrypts a purpose-bound expiring payload without exposing the secret" do
    user = create_user
    token, secret = token_for(user)

    payload = EmailVerificationDeliveryPayload.dump(
      secret: secret, user_id: user.id, token_id: token.id, locale: "zh-CN", expires_at: 1.minute.from_now
    )
    value = EmailVerificationDeliveryPayload.load(payload)

    assert_equal secret, value.secret
    assert_equal user.id, value.user_id
    assert_equal token.id, value.token_id
    assert_equal "zh-CN", value.locale
    assert_not_includes payload, secret
    assert_not_includes payload, user.email_address
  end

  test "rejects tampering wrong purpose and expiry" do
    user = create_user
    token, secret = token_for(user)
    payload = EmailVerificationDeliveryPayload.dump(
      secret: secret, user_id: user.id, token_id: token.id, locale: "ja", expires_at: 1.minute.from_now
    )

    assert_nil EmailVerificationDeliveryPayload.load("#{payload}x")
    travel 2.minutes do
      assert_nil EmailVerificationDeliveryPayload.load(payload)
    end
  end

  test "rejects malformed decrypted fields" do
    secret = EmailVerificationToken.generate_secret
    encryptor = EmailVerificationDeliveryPayload.send(:encryptor)
    payload = encryptor.encrypt_and_sign(
      { "secret" => secret, "user_id" => "1", "token_id" => 2, "locale" => "en" },
      purpose: EmailVerificationDeliveryPayload::PURPOSE
    )

    assert_nil EmailVerificationDeliveryPayload.load(payload)
  end
end
