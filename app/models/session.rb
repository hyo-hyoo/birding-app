class Session < ApplicationRecord
  LIFETIME = 30.days
  AuthenticationResult = Data.define(:status, :session)

  belongs_to :user
  attr_readonly :user_id, :created_at, :expires_at
  before_validation :set_lifetime, on: :create
  validates :expires_at, presence: true, comparison: { greater_than: :created_at }

  scope :active, ->(at = Time.current) { where("expires_at > ?", at) }

  # This is the only credential-to-session entry point. Never hash under the row lock.
  def self.authenticate(email_address:, password:)
    failure = AuthenticationResult.new(status: :invalid_credentials, session: nil)
    return failure unless email_address.is_a?(String) && password.is_a?(String) && password.present?

    user = User.find_by(email_address: email_address)
    unless user
      # Same bcrypt work as Rails authenticate_by, even for an unknown account.
      User.new(password: password)
      return failure
    end
    return failure unless user.authenticate(password)

    authenticated_digest = user.password_digest.dup
    transaction do
      locked_user = User.lock.find_by(id: user.id)
      if !locked_user || locked_user.password_digest != authenticated_digest
        failure
      elsif !locked_user.email_verified?
        AuthenticationResult.new(status: :unverified, session: nil)
      else
        AuthenticationResult.new(status: :authenticated, session: create!(user: locked_user))
      end
    end
  end

  def expired?(at = Time.current)
    expires_at <= at
  end

  private
    def set_lifetime
      self.created_at = self.updated_at = Time.current
      self.expires_at = created_at + LIFETIME
    end
end
