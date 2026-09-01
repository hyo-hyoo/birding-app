class SessionsController < ApplicationController
  include PendingEmailVerification
  allow_unauthenticated_access only: %i[new create]
  before_action :redirect_authenticated_user, only: %i[new create]

  def new; end

  def create
    @email_address = params[:email_address]
    result = authenticate_session(
      email_address: @email_address,
      password: params[:password]
    )
    case result.status
    when :authenticated
      forget_pending_email
      redirect_to after_authentication_url
    when :unverified
      remember_pending_email(User.normalize_value_for(:email_address, params[:email_address]))
      @login_error = :unverified
      render :new, status: :unprocessable_content
    else
      @login_error = :invalid_credentials
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private
    def redirect_authenticated_user
      redirect_to observations_path if authenticated?
    end
end
