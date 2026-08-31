require "test_helper"
require_relative "../support/account_test_support"

class UserTest < ActiveSupport::TestCase
  include AccountTestSupport

  test "new accounts are unverified and store only an authenticated digest" do
    user = create_user
    assert_not user.email_verified?
    assert_not_equal PASSWORD, user.password_digest
    assert_equal user, user.authenticate(PASSWORD)
    assert_not user.authenticate("Wrong123")
    assert_not_includes User.column_names, "password"
    assert_not_respond_to user, :password_reset_token
    assert_empty user.sessions
  end

  test "email normalization applies to writing and lookup without alias merging" do
    user = create_user(email_address: "  A.B+Bird@Example.TEST\t")
    assert_equal "a.b+bird@example.test", user.email_address
    assert_equal user, User.find_by(email_address: " A.B+Bird@EXAMPLE.test ")
    assert_nil User.find_by(email_address: "ab@example.test")
    assert_not build_user(email_address: " A.B+Bird@example.test ").valid?
  end

  test "email requires valid format and at most 255 characters" do
    [ nil, "", " ", "not-an-email", "a@", "a\nb@example.test", "a" * 244 + "@example.test" ].each do |email|
      user = build_user(email_address: email)
      assert_not user.valid?, email.inspect
      assert user.errors[:email_address].any?
    end
    assert build_user(email_address: "a" * 242 + "@example.test").valid?
  end

  test "password accepts the two length boundaries and either letter case" do
    [ "a1234567", "Z1234567", "a" * 19 + "1" ].each do |password|
      assert build_user(password: password, password_confirmation: password).valid?
    end
  end

  test "password rejects missing short long non ASCII and single category values" do
    [ nil, "", "a123456", "a" * 20 + "1", "abcdefgh", "12345678", "Bird 123", "Bird!123", "鸟1234567", "あ1234567", "Ａ1234567", "Bird123\n" ].each do |password|
      user = build_user(password: password, password_confirmation: password)
      assert_not user.valid?, password.inspect
      assert user.errors[:password].any?
    end
  end

  test "password confirmation is required and must match" do
    [ nil, "", "Other123" ].each do |confirmation|
      user = build_user(password_confirmation: confirmation)
      assert_not user.valid?
      assert user.errors[:password_confirmation].any?
    end
  end

  test "updating verification does not require a plaintext password" do
    user = create_user.reload
    digest = user.password_digest
    user.update!(email_verified_at: Time.current)
    assert user.email_verified?
    assert_equal digest, user.reload.password_digest
  end

  test "a user with sessions cannot be destroyed through its association" do
    user = create_user(email_verified_at: Time.current)
    session = login(user).session
    assert_not user.destroy
    assert Session.exists?(session.id)
    assert User.exists?(user.id)
  end
end
