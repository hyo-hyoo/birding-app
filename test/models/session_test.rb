require "test_helper"
require_relative "../support/account_test_support"

class SessionTest < ActiveSupport::TestCase
  include AccountTestSupport

  test "only verified correct credentials establish a session" do
    user = create_user
    assert_no_difference "Session.count" do
      assert_equal :unverified, login(user).status
      assert_equal :invalid_credentials, login(user, password: "Wrong123").status
      assert_equal :invalid_credentials, Session.authenticate(email_address: "missing@example.test", password: PASSWORD).status
    end
    user.update!(email_verified_at: Time.current)
    assert_difference "Session.count", 1 do
      result = login(user)
      assert_equal :authenticated, result.status
      assert_equal user, result.session.user
    end
  end

  test "missing and malformed credentials cannot establish sessions" do
    assert_no_difference "Session.count" do
      [ nil, "", [], {} ].each do |password|
        result = Session.authenticate(email_address: "nobody@example.test", password: password)
        assert_equal :invalid_credentials, result.status
        assert_nil result.session
      end
      assert_equal :invalid_credentials, Session.authenticate(email_address: [], password: PASSWORD).status
    end
  end

  test "unknown account still performs bcrypt work outside a transaction" do
    calls = []
    trace = TracePoint.new(:call) do |event|
      if event.method_id == :password= && event.self.is_a?(User)
        calls << [ event.self.password_digest, User.connection_pool.active_connection?&.transaction_open? ]
      end
    end
    trace.enable { Session.authenticate(email_address: "absent@example.test", password: PASSWORD) }
    assert_equal 1, calls.size
    assert_nil calls.first.first
    # This class uses a fixture transaction; the dedicated concurrency test checks
    # transaction/row-lock ordering without that outer test transaction.
  end

  test "expiry is fixed at 30 days and is exclusive at its boundary" do
    user = create_user(email_verified_at: Time.current)
    travel_to Time.utc(2026, 8, 31, 12) do
      session = login(user).session.reload
      assert_equal Time.current, session.created_at
      assert_equal Time.current + 30.days, session.expires_at
      assert_not session.expired?(session.expires_at - Rational(1, 1_000_000))
      assert session.expired?(session.expires_at)
      assert Session.active(session.expires_at - Rational(1, 1_000_000)).exists?(session.id)
      assert_not Session.active(session.expires_at).exists?(session.id)
    end
  end

  test "creation controls timestamps and normal updates cannot extend expiry" do
    user = create_user(email_verified_at: Time.current)
    travel_to Time.utc(2026, 8, 31, 12) do
      session = Session.create!(user: user, created_at: 1.year.ago, expires_at: 1.year.from_now)
      assert_equal Time.current, session.created_at
      assert_equal Time.current + 30.days, session.expires_at
      assert_raises(ActiveRecord::ReadonlyAttributeError) { session.update!(expires_at: 1.year.from_now) }
      assert_raises(ActiveRecord::ReadonlyAttributeError) { session.update!(user_id: user.id + 1) }
    end
  end

  test "multiple logins are independent and deleting one does not affect another" do
    user = create_user(email_verified_at: Time.current)
    first = login(user).session
    second = login(user).session
    assert_not_equal first.id, second.id
    first.destroy!
    assert_not Session.exists?(first.id)
    assert Session.exists?(second.id)
  end

  test "Current delegates user and resets identity" do
    user = create_user(email_verified_at: Time.current)
    Current.session = login(user).session
    assert_equal user, Current.user
    Current.reset
    assert_nil Current.session
    assert_nil Current.user
  ensure
    Current.reset
  end
end
