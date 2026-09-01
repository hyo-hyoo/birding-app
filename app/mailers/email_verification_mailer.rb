require "uri"

class EmailVerificationMailer < ApplicationMailer
  self.raise_delivery_errors = true

  def verification
    locale = normalized_locale(params[:locale])
    @verification_url = verification_url(params.fetch(:secret))
    I18n.with_locale(locale) do
      mail(to: params.fetch(:email_address), subject: I18n.t("email_verification_mailer.verification.subject"))
    end
  end

  private
    def normalized_locale(locale)
      candidate = locale.to_s
      I18n.available_locales.map(&:to_s).include?(candidate) ? candidate : I18n.default_locale
    end

    def verification_url(secret)
      options = self.class.default_url_options
      scheme = options[:protocol].presence&.delete_suffix("://") || "http"
      URI::Generic.build(
        scheme: scheme,
        host: options.fetch(:host),
        port: options[:port],
        path: "/email-verification",
        query: URI.encode_www_form(token: secret)
      ).to_s
    end
end
