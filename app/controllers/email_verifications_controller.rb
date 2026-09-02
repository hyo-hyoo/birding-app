class EmailVerificationsController < ApplicationController
  include PendingEmailVerification
  allow_unauthenticated_access

  def show
    @token = params[:token]
    @result = if @token.present?
      EmailVerificationToken.check(@token)
    else
      status = session.delete(:email_verification_result)&.to_sym || :invalid
      EmailVerificationToken::Result.new(status: status, masked_email: nil)
    end
  end

  def update
    @token = params[:token]
    @result = EmailVerificationToken.confirm(@token)
    if @result.status == :verified
      forget_pending_email
      redirect_to new_session_path, notice: t("account_flow.login.verification_success")
    else
      session[:email_verification_result] = @result.status.to_s
      redirect_to email_verification_path
    end
  end
end
