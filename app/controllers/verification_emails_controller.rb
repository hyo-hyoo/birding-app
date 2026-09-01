class VerificationEmailsController < ApplicationController
  include PendingEmailVerification
  allow_unauthenticated_access

  def show
    @result = verification_result || :accepted
    @can_resend = pending_email.present?
  end

  def new; end

  def create
    email_address = params[:email_address].presence || pending_email
    unless email_address
      @input_error = :missing_email
      return render :new, status: :unprocessable_content
    end

    result = EmailVerificationRequest.resend(
      email_address: email_address,
      ip_address: request.remote_ip,
      locale: I18n.locale
    )
    if result == :invalid_email
      @email_address = email_address
      @input_error = :invalid_email
      render :new, status: :unprocessable_content
    else
      remember_pending_email(User.normalize_value_for(:email_address, email_address)) if params[:email_address].present?
      remember_verification_result(result)
      redirect_to verification_email_path
    end
  end
end
