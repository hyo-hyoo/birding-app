require "openssl"

class VerificationRateLimitKey < ApplicationRecord
  has_many :verification_send_attempts, dependent: :restrict_with_error
  attr_readonly :scope, :subject_digest

  validates :scope, inclusion: { in: %w[email ip] }
  validates :subject_digest, format: { with: /\A[0-9a-f]{64}\z/ }
  # Uniqueness is enforced by the database so create_or_find_by! can resolve races.

  def self.subject(scope, normalized_value)
    raise ArgumentError, "Unknown rate-limit scope" unless %w[email ip].include?(scope)

    key = Rails.application.key_generator.generate_key("birding-app/verification-rate-limit/v1", 32)
    { scope: scope, subject_digest: OpenSSL::HMAC.hexdigest("SHA256", key, "#{scope}\0#{normalized_value}") }
  end
end
