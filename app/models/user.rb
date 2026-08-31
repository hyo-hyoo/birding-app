class User < ApplicationRecord
  has_secure_password reset_token: false
  has_many :sessions, dependent: :restrict_with_error
  has_many :email_verification_tokens, dependent: :restrict_with_error

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, length: { maximum: 255 },
    format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :password, length: { in: 8..20 },
    format: { with: /\A(?=.*[A-Za-z])(?=.*[0-9])[A-Za-z0-9]+\z/ }, if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { password.present? }

  def email_verified?
    email_verified_at.present?
  end
end
