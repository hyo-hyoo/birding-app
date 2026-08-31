# Rails authentication-generator foundation; business routes are connected in M2.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    helper_method :authenticated?
  end

  private
    def authenticated?
      Current.session.present?
    end

    def resume_session
      session_id = cookies.encrypted[:session_id]
      Current.session = if session_id.is_a?(Integer) && session_id.positive?
        Session.active.find_by(id: session_id)
      end
      unless Current.session
        cookies.delete(:session_id, path: "/") if cookies[:session_id]
      end
    end

    def authenticate_session(email_address:, password:)
      Session.authenticate(email_address: email_address, password: password).tap do |result|
        if result.session
          Current.session = result.session
          cookies.encrypted[:session_id] = {
            value: result.session.id, expires: result.session.expires_at,
            httponly: true, same_site: :lax, secure: Rails.env.production?, path: "/"
          }
        end
      end
    end

    def terminate_session
      Current.session&.destroy!
      Current.session = nil
      cookies.delete(:session_id, path: "/")
    end
end
