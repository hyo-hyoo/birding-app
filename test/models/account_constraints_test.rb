require "test_helper"
require_relative "../support/account_test_support"

class AccountConstraintsTest < ActiveSupport::TestCase
  include AccountTestSupport

  test "users enforce NOT NULL nonempty checks and unique email without model validations" do
    user = create_user
    row = user.attributes.except("id")
    assert_raises(ActiveRecord::RecordNotUnique) { User.insert_all!([ row ]) }
    [ "email_address", "password_digest" ].each do |column|
      assert_raises(ActiveRecord::NotNullViolation) { User.insert_all!([ row.merge(column => nil) ]) }
      error = assert_raises(ActiveRecord::StatementInvalid) { User.insert_all!([ row.merge(column => "") ]) }
      assert_equal 3819, error.cause.error_number
    end
  end

  test "session requires user expiry and strictly increasing timestamps" do
    user = create_user
    now = Time.current
    row = { user_id: user.id, created_at: now, updated_at: now, expires_at: now + 30.days }
    [ :user_id, :expires_at, :created_at, :updated_at ].each do |column|
      assert_raises(ActiveRecord::NotNullViolation) { Session.insert_all!([ row.merge(column => nil) ]) }
    end
    [ now, now - 1.second ].each do |expiry|
      error = assert_raises(ActiveRecord::StatementInvalid) { Session.insert_all!([ row.merge(expires_at: expiry) ]) }
      assert_equal 3819, error.cause.error_number
    end
    assert_raises(ActiveRecord::InvalidForeignKey) { Session.insert_all!([ row.merge(user_id: -1) ]) }
  end

  test "foreign key restricts parent deletion and primary key updates" do
    user = create_user(email_verified_at: Time.current)
    login(user)
    assert_raises(ActiveRecord::InvalidForeignKey) { User.where(id: user.id).delete_all }
    assert_raises(ActiveRecord::InvalidForeignKey) { User.where(id: user.id).update_all(id: -1) }
  end

  test "schema preserves exact collations signed keys precision indexes and check constraints" do
    connection = ActiveRecord::Base.connection
    users = connection.columns(:users).index_by(&:name)
    sessions = connection.columns(:sessions).index_by(&:name)
    assert_equal "utf8mb4_0900_bin", users.fetch("email_address").collation
    assert_equal "utf8mb4_0900_bin", users.fetch("password_digest").collation
    assert_equal "bigint", users.fetch("id").sql_type
    assert_equal "bigint", sessions.fetch("user_id").sql_type
    [ users.fetch("email_verified_at"), users.fetch("created_at"), sessions.fetch("expires_at") ].each do |column|
      assert_equal 6, column.precision
      assert_nil column.default
    end
    assert_equal [ "chk_users_email_present", "chk_users_password_present" ], connection.check_constraints(:users).map(&:name).sort
    assert_equal [ "chk_sessions_expiry" ], connection.check_constraints(:sessions).map(&:name)
    email_index = connection.indexes(:users).find { |index| index.name == "uq_users_email" }
    assert email_index.unique
    assert_equal [ "email_address" ], email_index.columns
    assert_equal [ "expires_at", "id" ], connection.indexes(:sessions).find { |index| index.name == "ix_sessions_expiry" }.columns
    rules = connection.select_one("SELECT DELETE_RULE, UPDATE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'sessions'")
    # schema.rb omits the default action. InnoDB's NO ACTION is immediately
    # restrictive too; the preceding test proves both actual DELETE/UPDATE fail.
    engines = connection.select_values("SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('users', 'sessions')")
    assert_equal [ "InnoDB", "InnoDB" ], engines
    rules.transform_values! { |rule| rule == "NO ACTION" ? "RESTRICT" : rule }
    assert_equal({ "DELETE_RULE" => "RESTRICT", "UPDATE_RULE" => "RESTRICT" }, rules)
    assert_equal %w[created_at expires_at id updated_at user_id], Session.column_names.sort
  end
end
