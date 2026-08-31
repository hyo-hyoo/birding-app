require "test_helper"
require_relative "../support/verification_test_support"

class VerificationConstraintsTest < ActiveSupport::TestCase
  include VerificationTestSupport

  test "only one active token is allowed but multiple historical tokens are allowed" do
    user = create_user
    token, = token_for(user)
    row = token.attributes.except("id")
    assert_raises(ActiveRecord::RecordNotUnique) { EmailVerificationToken.insert_all!([ row.merge("token_digest" => "a" * 64) ]) }
    token.update!(active_slot: nil, invalidated_at: Time.current, invalidation_reason: "superseded")
    row = token.reload.attributes.except("id")
    EmailVerificationToken.insert_all!([ row.merge("token_digest" => "b" * 64) ])
    assert_equal 2, user.email_verification_tokens.where(active_slot: nil).count
    token_for(user)
    assert_equal 1, user.email_verification_tokens.where(active_slot: 1).count
    assert_raises(ActiveRecord::RecordNotUnique) { EmailVerificationToken.insert_all!([ row ]) }
  end

  test "token CHECK rejects partial state including SQL UNKNOWN cases" do
    token, = token_for(create_user)
    [
      { active_slot: nil }, { active_slot: 0 }, { active_slot: 2 },
      { invalidated_at: Time.current }, { invalidation_reason: "consumed" },
      { active_slot: nil, invalidated_at: Time.current },
      { active_slot: nil, invalidation_reason: "consumed" },
      { active_slot: nil, invalidated_at: Time.current, invalidation_reason: "other" },
      { active_slot: nil, invalidated_at: Time.current, invalidation_reason: "CONSUMED" }
    ].each do |attributes|
      error = assert_raises(ActiveRecord::StatementInvalid) { EmailVerificationToken.where(id: token.id).update_all(attributes) }
      assert_equal 3819, error.cause.error_number
    end
    assert_equal 1, token.reload.active_slot
  end

  test "token digest time nulls and ownership are enforced without Model validation" do
    token, = token_for(create_user)
    [ "a" * 63, "A" * 64, "g" * 64, "" ].each do |digest|
      error = assert_raises(ActiveRecord::StatementInvalid) { EmailVerificationToken.where(id: token.id).update_all(token_digest: digest) }
      assert_equal 3819, error.cause.error_number
    end
    [ :user_id, :token_digest, :expires_at, :created_at, :updated_at ].each do |column|
      assert_raises(ActiveRecord::NotNullViolation) { EmailVerificationToken.where(id: token.id).update_all(column => nil) }
    end
    assert_raises(ActiveRecord::StatementInvalid) { EmailVerificationToken.where(id: token.id).update_all(expires_at: token.created_at) }
    assert_raises(ActiveRecord::InvalidForeignKey) { EmailVerificationToken.where(id: token.id).update_all(user_id: -1) }
    assert_raises(ActiveRecord::InvalidForeignKey) { User.where(id: token.user_id).delete_all }
    assert_raises(ActiveRecord::InvalidForeignKey) { User.where(id: token.user_id).update_all(id: -1) }
  end

  test "rate subjects enforce unique scope and digest format" do
    key = VerificationRateLimitKey.create!(scope: "email", subject_digest: "a" * 64)
    row = key.attributes.except("id")
    assert_raises(ActiveRecord::RecordNotUnique) { VerificationRateLimitKey.insert_all!([ row ]) }
    [ { scope: "other" }, { scope: "EMAIL" }, { subject_digest: "A" * 64 }, { subject_digest: "a" * 63 } ].each do |attributes|
      error = assert_raises(ActiveRecord::StatementInvalid) { VerificationRateLimitKey.where(id: key.id).update_all(attributes) }
      assert_equal 3819, error.cause.error_number
    end
    [ :scope, :subject_digest, :created_at, :updated_at ].each do |column|
      assert_raises(ActiveRecord::NotNullViolation) { VerificationRateLimitKey.where(id: key.id).update_all(column => nil) }
    end
  end

  test "attempt admission boolean kind and foreign key survive raw SQL writes" do
    key = VerificationRateLimitKey.create!(scope: "ip", subject_digest: "b" * 64)
    attempt = key.verification_send_attempts.create!(kind: "resend", rate_limit_passed: false)
    [ 2, -1 ].each do |invalid_value|
      error = assert_raises(ActiveRecord::StatementInvalid) do
        ActiveRecord::Base.connection.execute("UPDATE verification_send_attempts SET rate_limit_passed = #{invalid_value} WHERE id = #{attempt.id}")
      end
      assert_equal 3819, error.cause.error_number
    end
    assert_raises(ActiveRecord::StatementInvalid) { VerificationSendAttempt.where(id: attempt.id).update_all(kind: "RESEND") }
    [ :verification_rate_limit_key_id, :kind, :rate_limit_passed, :created_at ].each do |column|
      assert_raises(ActiveRecord::NotNullViolation) { VerificationSendAttempt.where(id: attempt.id).update_all(column => nil) }
    end
    assert_raises(ActiveRecord::InvalidForeignKey) { VerificationSendAttempt.where(id: attempt.id).update_all(verification_rate_limit_key_id: -1) }
    assert_raises(ActiveRecord::InvalidForeignKey) { VerificationRateLimitKey.where(id: key.id).delete_all }
    assert_raises(ActiveRecord::InvalidForeignKey) { VerificationRateLimitKey.where(id: key.id).update_all(id: -1) }
    assert_raises(ActiveRecord::ReadonlyAttributeError) { attempt.update!(rate_limit_passed: true) }
  end

  test "schema contains expected exact columns unique slots indexes and timestamps" do
    c = ActiveRecord::Base.connection
    assert_equal "tinyint", c.columns(:email_verification_tokens).find { |column| column.name == "active_slot" }.sql_type
    {
      email_verification_tokens: %w[token_digest invalidation_reason],
      verification_rate_limit_keys: %w[scope subject_digest],
      verification_send_attempts: %w[kind]
    }.each do |table, names|
      c.columns(table).select { |column| names.include?(column.name) }.each do |column|
        assert_equal "utf8mb4_0900_bin", column.collation
      end
      c.columns(table).select { |column| column.type == :datetime }.each do |column|
        assert_equal 6, column.precision
      end
      assert_equal "bigint", c.columns(table).find { |column| column.name == "id" }.sql_type
    end
    slot_index = c.indexes(:email_verification_tokens).find { |index| index.name == "uq_email_verification_active_user" }
    assert slot_index.unique
    assert_equal %w[user_id active_slot], slot_index.columns
    window_index = c.indexes(:verification_send_attempts).find { |index| index.name == "ix_verification_attempt_subject_time" }
    assert_equal %w[verification_rate_limit_key_id created_at id], window_index.columns
    assert_not VerificationSendAttempt.column_names.include?("dispatch_attempted")
    assert_equal false, c.columns(:verification_send_attempts).find { |column| column.name == "rate_limit_passed" }.default
  end
end
