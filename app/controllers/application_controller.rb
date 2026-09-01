class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :use_locale

  private
    def use_locale(&block)
      locale = explicit_locale || saved_locale || browser_locale
      remember_locale(locale) if explicit_locale
      I18n.with_locale(locale, &block)
    end

    def explicit_locale
      locale_from(params[:locale])
    end

    def saved_locale
      locale_from(cookies.encrypted[:locale])
    end

    def browser_locale
      primary = request.headers["Accept-Language"].to_s.split(",", 2).first.to_s.strip.downcase
      primary.start_with?("zh") ? :"zh-CN" : :ja
    end

    def locale_from(value)
      I18n.available_locales.find { |locale| locale.to_s == value.to_s }
    end

    def remember_locale(locale)
      cookies.encrypted[:locale] = {
        value: locale.to_s, expires: 1.year.from_now, httponly: true,
        same_site: :lax, secure: Rails.env.production?, path: "/"
      }
    end
end
