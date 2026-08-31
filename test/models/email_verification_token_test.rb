require "test_helper"
require_relative "../support/verification_test_support"

class EmailVerificationTokenTest < ActiveSupport::TestCase
  include VerificationTestSupport

  test "secret is random 256 bits and only its purpose-separated digest is stored" do
    user = create_user
    token, secret = token_for(user)
    assert_equal 32, Base64.urlsafe_decode64(secret).bytesize
    assert_not_equal secret, EmailVerificationToken.generate_secret
    assert_match(/\A[0-9a-f]{64}\z/, token.token_digest)
    assert_not_equal Digest::SHA256.hexdigest(secret), token.token_digest
    assert_not_equal Digest::SHA256.hexdigest("birding-app/password-reset/v1\0#{secret}"), token.token_digest
    assert_not_includes token.attributes.values, secret
    assert_nil EmailVerificationToken.digest_for(" #{secret}")
    assert_nil EmailVerificationToken.digest_for([])
  end

  test "checking a valid link is read only and exposes only a masked mailbox" do
    user = create_user
    token, secret = token_for(user)
    before = [ user.reload.attributes, token.reload.attributes ]
    2.times do
      result = EmailVerificationToken.check(secret)
      assert_equal :valid, result.status
      assert_equal "***@example.test", result.masked_email
      assert_not_equal user.email_address, result.masked_email
    end
    assert_equal before, [ user.reload.attributes, token.reload.attributes ]
    assert_empty user.sessions
  end

  test "confirmation verifies and consumes atomically without creating a session" do
    user = create_user
    token, secret = token_for(user)
    assert_no_difference "Session.count" do
      assert_equal :verified, EmailVerificationToken.confirm(secret).status
    end
    assert user.reload.email_verified?
    assert_nil token.reload.active_slot
    assert_equal "consumed", token.invalidation_reason
    assert_equal user.email_verified_at, token.invalidated_at
    assert_equal :consumed, EmailVerificationToken.check(secret).status
    assert_equal :consumed, EmailVerificationToken.confirm(secret).status
  end

  test "15 minute expiry is exclusive and fixed on the server" do
    travel_to Time.utc(2026, 8, 31, 12) do
      user = create_user
      token, secret = token_for(user)
      assert_equal Time.current + 15.minutes, token.expires_at
      travel 15.minutes - 1.second
      assert_equal :valid, EmailVerificationToken.check(secret).status
      travel 1.second
      assert_equal :expired, EmailVerificationToken.check(secret).status
      assert_equal :expired, EmailVerificationToken.confirm(secret).status
      assert_not user.reload.email_verified?
      assert_equal 1, token.reload.active_slot
      assert_raises(ActiveRecord::ReadonlyAttributeError) { token.expires_at = 1.day.from_now }
    end
  end

  test "superseded invalid and already verified credentials do not mutate records" do
    user = create_user
    token, secret = token_for(user)
    token.update!(active_slot: nil, invalidated_at: Time.current, invalidation_reason: "superseded")
    assert_equal :superseded, EmailVerificationToken.confirm(secret).status
    assert_not user.reload.email_verified?
    [ nil, "invalid", [], {}, EmailVerificationToken.generate_secret, token.token_digest ].each do |value|
      assert_equal :invalid, EmailVerificationToken.confirm(value).status
    end
    _, current_secret = token_for(user)
    user.update!(email_verified_at: Time.current)
    before = user.reload.attributes
    assert_equal :already_verified, EmailVerificationToken.confirm(current_secret).status
    assert_equal before, user.reload.attributes
  end

  test "cleared historical credentials become uniformly invalid" do
    user = create_user
    token, secret = token_for(user)
    token.destroy!
    assert_equal :invalid, EmailVerificationToken.check(secret).status
    assert_not user.reload.email_verified?
  end

  test "Model rejects inconsistent active and historical state" do
    token, = token_for(create_user)
    [ { active_slot: nil }, { invalidation_reason: "consumed" }, { invalidated_at: Time.current }, { active_slot: 2 } ].each do |attributes|
      token.reload.assign_attributes(attributes)
      assert_not token.valid?
    end
    token.reload.assign_attributes(active_slot: nil, invalidated_at: Time.current, invalidation_reason: "superseded")
    assert token.valid?
  end
end
