class EmailVerificationRequest
  def self.resend(email_address:, ip_address:, locale:)
    admission = VerificationRateLimiter.resend(email_address: email_address, ip_address: ip_address)
    return admission unless admission == :allowed

    normalized_email = User.normalize_value_for(:email_address, email_address)
    user = User.find_by(email_address: normalized_email)
    EmailVerificationIssuer.issue(user_id: user.id, locale: locale) if user && !user.email_verified?
    :accepted
  rescue VerificationRateLimiter::AdmissionUnavailable
    :temporarily_unavailable
  end
end
