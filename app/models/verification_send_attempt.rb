class VerificationSendAttempt < ApplicationRecord
  belongs_to :verification_rate_limit_key
  attr_readonly :verification_rate_limit_key_id, :kind, :rate_limit_passed, :created_at
  validates :kind, inclusion: { in: %w[initial resend] }
  validates :rate_limit_passed, inclusion: { in: [ true, false ] }
end
