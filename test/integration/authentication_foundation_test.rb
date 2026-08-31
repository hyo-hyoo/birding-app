require "test_helper"
require_relative "../support/account_test_support"

# Test-only HTTP harness: not mounted in the application and not a product API.
class AuthenticationProbeController < ActionController::Base
  include Authentication
  protect_from_forgery with: :exception
  self.allow_forgery_protection = true

  def show
    render json: { user_id: Current.user&.id, csrf: form_authenticity_token }
  end

  def create
    result = authenticate_session(**params.permit(:email_address, :password).to_h.symbolize_keys)
    render json: { result: result.status }, status: result.session ? :ok : :unauthorized
  end

  def destroy
    terminate_session
    head :no_content
  end

  def protected_page
    head authenticated? ? :ok : :unauthorized
  end
end

class AuthenticationFoundationTest < ActionDispatch::IntegrationTest
  include AccountTestSupport

  ROUTES = ActionDispatch::Routing::RouteSet.new
  ROUTES.draw do
    get "/", to: "authentication_probe#show"
    post "/session", to: "authentication_probe#create"
    delete "/session", to: "authentication_probe#destroy"
    get "/protected", to: "authentication_probe#protected_page"
  end
  TEST_APP = Rack::Builder.new do
    use ActionDispatch::Executor, Rails.application.executor
    use ActionDispatch::Cookies
    use ActionDispatch::Session::CookieStore, key: "_m1_probe"
    run ROUTES
  end

  def app
    ->(env) { TEST_APP.call(Rails.application.env_config.merge(env)) }
  end

  setup do
    @user = create_user(email_verified_at: Time.current)
  end

  test "login uses an encrypted HttpOnly Lax absolute expiry cookie" do
    sign_in
    record = @user.sessions.sole
    raw_cookie = cookies[:session_id]
    assert raw_cookie.present?
    assert_not_equal record.id.to_s, raw_cookie
    header = Array(response.headers["set-cookie"]).find { |value| value.start_with?("session_id=") }
    assert_match(/httponly/i, header)
    assert_match(/samesite=lax/i, header)
    assert_match(/expires=#{Regexp.escape(record.expires_at.httpdate)}/i, header)
    assert_no_match(/; secure/i, header)
    get "/"
    assert_equal @user.id, response.parsed_body["user_id"]
    assert_equal raw_cookie, cookies[:session_id]
    assert_no_match(/(?:\A|\n)session_id=/, Array(response.headers["set-cookie"]).join("\n"))
  end

  test "forged and tampered cookies cannot authenticate" do
    sign_in
    raw_cookie = cookies[:session_id]
    [ @user.sessions.sole.id.to_s, raw_cookie.reverse ].each do |value|
      cookies[:session_id] = value
      get "/protected"
      assert_response :unauthorized
      assert_session_cookie_deleted
    end
  end

  test "revoked session is rejected even with a previously valid cookie" do
    sign_in
    Session.where(user: @user).delete_all
    get "/protected"
    assert_response :unauthorized
    assert_session_cookie_deleted
    get "/"
    assert_response :ok
    assert_nil response.parsed_body["user_id"]
  end

  test "expiry is enforced by the database even if a browser keeps its cookie" do
    travel_to Time.utc(2026, 8, 31, 12) do
      sign_in
      raw_cookie = cookies[:session_id]
      record = @user.sessions.sole
      # Cookie replay bypasses browser expiry, not the server's expiry check.
      travel 30.days
      cookies[:session_id] = raw_cookie
      get "/protected"
      assert_response :unauthorized
      assert_session_cookie_deleted
      assert record.reload.expired?
      assert Session.exists?(record.id), "expiry must not depend on physical cleanup"
    end
  end

  test "an unexpired encrypted cookie cannot override database expiry" do
    travel_to Time.utc(2026, 8, 31, 12) do
      sign_in
      raw_cookie = cookies[:session_id]
      record = @user.sessions.sole
      travel 1.day
      # Deliberate SQL bypass for a negative test: the encrypted cookie still has
      # 29 days left, so only the database check can reject this session.
      Session.where(id: record.id).update_all(expires_at: Time.current)
      cookies[:session_id] = raw_cookie
      get "/protected"
      assert_response :unauthorized
      assert_session_cookie_deleted
    end
  end

  test "logout revokes only this session and a replay cannot restore it" do
    other = login(@user).session
    sign_in
    raw_cookie = cookies[:session_id]
    get "/"
    token = response.parsed_body["csrf"]
    delete "/session", headers: { "X-CSRF-Token" => token }
    assert_response :no_content
    assert_session_cookie_deleted
    assert_equal [ other.id ], @user.sessions.pluck(:id)
    cookies[:session_id] = raw_cookie
    get "/protected"
    assert_response :unauthorized
  end

  test "anonymous public request never inherits another request identity" do
    sign_in
    get "/"
    assert_equal @user.id, response.parsed_body["user_id"]
    reset!
    get "/"
    assert_response :ok
    assert_nil response.parsed_body["user_id"]
    get "/protected"
    assert_response :unauthorized
  end

  test "unverified login does not set session cookie or session record" do
    @user.update!(email_verified_at: nil)
    get "/"
    assert_no_difference "Session.count" do
      post "/session", params: { email_address: @user.email_address, password: PASSWORD }, headers: { "X-CSRF-Token" => response.parsed_body["csrf"] }
    end
    assert_response :unauthorized
    assert_nil cookies[:session_id]
  end

  test "login and logout reject missing CSRF tokens with no database mutation" do
    assert_no_difference "Session.count" do
      assert_raises(ActionController::InvalidAuthenticityToken) do
        post "/session", params: { email_address: @user.email_address, password: PASSWORD }
      end
    end
    sign_in
    assert_no_difference "Session.count" do
      assert_raises(ActionController::InvalidAuthenticityToken) { delete "/session" }
    end
  end

  private
    def assert_session_cookie_deleted
      assert cookies[:session_id].blank?
      header = Array(response.headers["set-cookie"]).find { |value| value.start_with?("session_id=") }
      assert_match(/expires=Thu, 01 Jan 1970/i, header)
    end

    def sign_in
      get "/"
      token = response.parsed_body["csrf"]
      post "/session", params: { email_address: @user.email_address, password: PASSWORD }, headers: { "X-CSRF-Token" => token }
      assert_response :ok
    end
end
