require "test_helper"
require_relative "../support/verification_test_support"

class MaintenanceCleanupTest < PersistentVerificationTestCase
  test "removes only sessions that expired before the current day" do
    travel_to Time.zone.local(2026, 9, 1, 12) do
      user = tracked_user(email_verified_at: Time.current)
      old = Session.create!(user: user)
      today = Session.create!(user: user)
      Session.where(id: old.id).update_all(
        created_at: Time.zone.local(2026, 8, 1, 23, 59, 59),
        expires_at: Time.zone.local(2026, 8, 31, 23, 59, 59)
      )
      Session.where(id: today.id).update_all(
        created_at: Time.zone.local(2026, 8, 2, 0, 0, 0),
        expires_at: Time.zone.local(2026, 9, 1, 0, 0, 0)
      )

      result = MaintenanceCleanup.call(now: Time.current)

      assert_equal 1, result.sessions
      assert_not Session.exists?(old.id)
      assert Session.exists?(today.id)
      assert today.reload.expired?
    end
  end

  test "retains invalid tokens seven days and attempts twenty four hours then removes orphan keys" do
    now = Time.zone.local(2026, 9, 1, 12)
    old_history_user = tracked_user
    old_active_user = tracked_user
    recent_history_user = tracked_user
    recent_active_user = tracked_user
    old_history = recent_history = old_active = recent_active = nil
    travel_to now - 8.days do
      old_history, = token_for(old_history_user)
      old_history.update!(active_slot: nil, invalidated_at: Time.current, invalidation_reason: "superseded")
      old_active, = token_for(old_active_user)
    end
    travel_to now - 6.days do
      recent_history, = token_for(recent_history_user)
      recent_history.update!(active_slot: nil, invalidated_at: Time.current, invalidation_reason: "superseded")
      recent_active, = token_for(recent_active_user)
    end
    old_subject = email_subject("old-#{@email}")
    recent_subject = email_subject("recent-#{@email}")
    seed_attempt(old_subject, at: now - 25.hours, passed: true)
    seed_attempt(recent_subject, at: now - 23.hours, passed: true)

    result = MaintenanceCleanup.call(now: now)

    assert_equal 2, result.tokens
    assert_equal 1, result.attempts
    assert_equal 1, result.keys
    assert_not EmailVerificationToken.exists?(old_history.id)
    assert_not EmailVerificationToken.exists?(old_active.id)
    assert EmailVerificationToken.exists?(recent_history.id)
    assert EmailVerificationToken.exists?(recent_active.id)
    assert_nil VerificationRateLimitKey.find_by(old_subject)
    assert VerificationRateLimitKey.find_by(recent_subject)
  end
end
