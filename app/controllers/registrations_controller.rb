class RegistrationsController < ApplicationController
  include PendingEmailVerification
  allow_unauthenticated_access
  before_action :redirect_authenticated_user

  def new
    @user = User.new
  end

  def create
    result = AccountRegistration.register(**registration_params, locale: I18n.locale)
    @user = result.user
    @user.password = @user.password_confirmation = nil
    if result.status == :invalid
      if @user.errors.of_kind?(:email_address, :taken)
        remember_verification_result(:duplicate)
        redirect_to verification_email_path
      else
        render :new, status: :unprocessable_content
      end
    else
      remember_pending_email(@user.email_address)
      remember_verification_result(result.status)
      redirect_to verification_email_path
    end
  end

  private
    def registration_params
      params.require(:user).permit(:email_address, :password, :password_confirmation).to_h.symbolize_keys
    end

    def redirect_authenticated_user
      redirect_to observations_path if authenticated?
    end
end
