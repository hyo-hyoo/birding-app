class MaintenanceCleanup
  Result = Data.define(:sessions, :tokens, :attempts, :keys)

  def self.call(now: Time.current)
    sessions = Session.where("expires_at < ?", now.beginning_of_day).delete_all
    tokens = EmailVerificationToken.where("invalidated_at < ?", now - 7.days).delete_all
    tokens += EmailVerificationToken.where(active_slot: 1).where("expires_at < ?", now - 7.days).delete_all
    attempts = VerificationSendAttempt.where("created_at < ?", now - 24.hours).delete_all
    keys = VerificationRateLimitKey.where.missing(:verification_send_attempts).delete_all
    Result.new(sessions: sessions, tokens: tokens, attempts: attempts, keys: keys)
  end
end
