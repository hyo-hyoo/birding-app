require "digest"

class EmailVerificationToken < ApplicationRecord
  LIFETIME = 15.minutes
  PURPOSE = "birding-app/email-verification/v1"
  Result = Data.define(:status, :masked_email)

  belongs_to :user
  attr_readonly :user_id, :token_digest, :created_at, :expires_at
  before_validation :set_lifetime, on: :create
  validates :token_digest, format: { with: /\A[0-9a-f]{64}\z/ }
  validates :expires_at, presence: true, comparison: { greater_than: :created_at }
  validate :consistent_state

  # Only generates a secret; issuance/rotation must also successfully enqueue mail
  # in the same User-locked transaction (M2-B). Never use create! as a resend flow.
  def self.generate_secret
    SecureRandom.urlsafe_base64(32)
  end

  def self.digest_for(secret)
    return unless secret.is_a?(String) && secret.match?(/\A[A-Za-z0-9_-]{43}\z/)

    Digest::SHA256.hexdigest("#{PURPOSE}\0#{secret}")
  end

  def self.check(secret)
    with_current_token(secret) { |user, token| result_for(user, token, Time.current) }
  end

  def self.confirm(secret)
    with_current_token(secret) do |user, token|
      now = Time.current
      result = result_for(user, token, now)
      if result.status == :valid
        user.update!(email_verified_at: now)
        token.update!(active_slot: nil, invalidated_at: now, invalidation_reason: "consumed")
        Result.new(status: :verified, masked_email: nil)
      else
        result
      end
    end
  end

  private_class_method def self.with_current_token(secret)
    digest = digest_for(secret)
    found = find_by(token_digest: digest) if digest
    invalid = Result.new(status: :invalid, masked_email: nil)
    return invalid unless found

    transaction do
      user = User.lock.find_by(id: found.user_id)
      token = user&.email_verification_tokens&.lock&.find_by(id: found.id, token_digest: digest)
      token ? yield(user, token) : invalid
    end
  end

  private_class_method def self.result_for(user, token, now)
    status = if token.invalidation_reason.present?
      token.invalidation_reason.to_sym
    elsif token.active_slot != 1
      :invalid
    elsif token.expires_at <= now
      :expired
    elsif user.email_verified?
      :already_verified
    else
      :valid
    end
    masked_email = "***@#{user.email_address.split('@', 2).last}" if status == :valid
    Result.new(status: status, masked_email: masked_email)
  end

  private
    def set_lifetime
      self.created_at = self.updated_at = Time.current
      self.expires_at = created_at + LIFETIME
    end

    def consistent_state
      active = active_slot == 1 && invalidated_at.nil? && invalidation_reason.nil?
      historical = active_slot.nil? && invalidated_at.present? && %w[consumed superseded].include?(invalidation_reason)
      errors.add(:base, :invalid) unless active || historical
    end
end
