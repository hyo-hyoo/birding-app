class FrontendPreviewsController < ApplicationController
  allow_unauthenticated_access
  around_action :use_preview_locale

  def login; end

  def register; end

  def verification_sent; end

  def verification_success; end

  def reset_request; end

  def reset_password; end

  def reset_success; end

  def history_empty; end

  def history; end

  def outline; end

  def editor; end

  def detail; end

  def settings; end

  def change_password; end

  private

  def use_preview_locale
    locale = I18n.available_locales.find { |available_locale| available_locale.to_s == params[:locale].to_s }

    I18n.with_locale(locale || I18n.default_locale) { yield }
  end
end
