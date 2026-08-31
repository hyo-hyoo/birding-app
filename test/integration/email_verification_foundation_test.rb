require "test_helper"
require_relative "../support/verification_test_support"

# Test-only HTTP wiring. The formal confirmation page is connected in M2-C.
class EmailVerificationProbeController < ActionController::Base
  protect_from_forgery with: :exception
  self.allow_forgery_protection = true

  def show
    result = EmailVerificationToken.check(params[:token])
    render json: result.to_h.merge(csrf: form_authenticity_token)
  end

  def create
    render json: EmailVerificationToken.confirm(params[:token]).to_h
  end
end

class EmailVerificationFoundationTest < ActionDispatch::IntegrationTest
  include VerificationTestSupport

  ROUTES = ActionDispatch::Routing::RouteSet.new
  ROUTES.draw do
    get "/verification", to: "email_verification_probe#show"
    post "/verification", to: "email_verification_probe#create"
  end
  TEST_APP = Rack::Builder.new do
    use ActionDispatch::Executor, Rails.application.executor
    use ActionDispatch::Cookies
    use ActionDispatch::Session::CookieStore, key: "_verification_probe"
    run ROUTES
  end

  def app
    ->(env) { TEST_APP.call(Rails.application.env_config.merge(env)) }
  end

  setup do
    @user = create_user
    @token, @secret = token_for(@user)
  end

  test "GET scanner visits never verify the account and POST confirms without logging in" do
    2.times do
      get "/verification", params: { token: @secret }
      assert_response :ok
      assert_equal "valid", response.parsed_body["status"]
      assert_not user_verified?
      assert_nil @token.reload.invalidated_at
      assert_not_includes response.body, @user.email_address
      assert_not_includes response.body, @secret
    end
    csrf = response.parsed_body["csrf"]
    assert_no_difference "Session.count" do
      post "/verification", params: { token: @secret }, headers: { "X-CSRF-Token" => csrf }
    end
    assert_equal "verified", response.parsed_body["status"]
    assert user_verified?
    assert_nil cookies[:session_id]
  end

  test "POST requires CSRF and cannot trust a browser-supplied success status or user ID" do
    assert_raises(ActionController::InvalidAuthenticityToken) { post "/verification", params: { token: @secret } }
    assert_not user_verified?
    get "/verification", params: { token: @secret }
    csrf = response.parsed_body["csrf"]
    post "/verification", params: { token: "forged", status: "verified", user_id: @user.id }, headers: { "X-CSRF-Token" => csrf }
    assert_equal "invalid", response.parsed_body["status"]
    assert_not user_verified?
    assert_equal 1, @token.reload.active_slot
  end

  test "confirmation rechecks token state changed after the GET" do
    get "/verification", params: { token: @secret }
    csrf = response.parsed_body["csrf"]
    @token.update!(active_slot: nil, invalidated_at: Time.current, invalidation_reason: "superseded")
    post "/verification", params: { token: @secret }, headers: { "X-CSRF-Token" => csrf }
    assert_equal "superseded", response.parsed_body["status"]
    assert_not user_verified?
  end

  private
    def user_verified?
      @user.reload.email_verified?
    end
end
