require "uri"

# Rails authentication-generator foundation connected to formal account routes in M2.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
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

    def require_authentication
      return if authenticated?

      session[:return_to_after_authenticating] = request.fullpath if request.get? && request.format.html?
      redirect_to new_session_path
    end

    def after_authentication_url
      path = session.delete(:return_to_after_authenticating)
      safe_internal_path?(path) ? path : observations_path
    end

    def safe_internal_path?(path)
      return false unless path.is_a?(String) && path.start_with?("/") && !path.start_with?("//") && !path.include?("\\")

      uri = URI.parse(path)
      uri.relative? && uri.host.nil?
    rescue URI::InvalidURIError
      false
    end
end
