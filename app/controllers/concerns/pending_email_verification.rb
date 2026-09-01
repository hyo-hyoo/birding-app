module PendingEmailVerification
  extend ActiveSupport::Concern

  private
    def remember_pending_email(email_address)
      cookies.encrypted[:pending_verification_email] = {
        value: email_address, expires: 1.day.from_now, httponly: true,
        same_site: :lax, secure: Rails.env.production?, path: "/"
      }
    end

    def pending_email
      value = cookies.encrypted[:pending_verification_email]
      value if value.is_a?(String) && value.length <= 255 && URI::MailTo::EMAIL_REGEXP.match?(value)
    end

    def forget_pending_email
      cookies.delete(:pending_verification_email, path: "/")
      session.delete(:verification_email_result)
    end

    def remember_verification_result(status)
      session[:verification_email_result] = status.to_s
    end

    def verification_result
      session.delete(:verification_email_result)&.to_sym
    end
end
