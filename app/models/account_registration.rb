class AccountRegistration
  Result = Data.define(:status, :user)

  def self.register(email_address:, password:, password_confirmation:, locale:)
    user = User.new(
      email_address: email_address,
      password: password,
      password_confirmation: password_confirmation
    )
    return Result.new(status: :invalid, user: user) unless user.save

    status = begin
      admission = VerificationRateLimiter.initial(email_address: user.email_address)
      if admission == :allowed
        issuance = EmailVerificationIssuer.issue(user_id: user.id, locale: locale)
        issuance.status == :queued ? :created_email_queued : :created_email_unavailable
      else
        :created_email_unavailable
      end
    rescue VerificationRateLimiter::AdmissionUnavailable
      :created_email_unavailable
    end
    Result.new(status: status, user: user)
  rescue ActiveRecord::RecordNotUnique
    user.errors.add(:email_address, :taken)
    Result.new(status: :invalid, user: user)
  end
end
