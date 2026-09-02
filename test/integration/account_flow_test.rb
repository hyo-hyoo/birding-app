require "test_helper"
require_relative "../support/account_flow_test_support"

class AccountFlowTest < ActionDispatch::IntegrationTest
  include AccountFlowTestSupport
  self.use_transactional_tests = false

  setup :setup_account_flow
  teardown :teardown_account_flow

  test "protected pages remember a safe internal return and authenticated account pages redirect away" do
    user = create_flow_user(email_verified_at: Time.current)

    get settings_path
    assert_redirected_to new_session_path
    post session_path, params: { email_address: user.email_address, password: AccountTestSupport::PASSWORD }
    assert_redirected_to settings_path
    get new_registration_path
    assert_redirected_to observations_path

    delete session_path
    assert_redirected_to new_session_path
    post session_path, params: {
      email_address: user.email_address, password: AccountTestSupport::PASSWORD,
      return_to: "//example.test/steal"
    }
    assert_redirected_to observations_path
  end

  test "locale uses explicit choice then encrypted cookie before browser language" do
    get new_session_path, headers: { "Accept-Language" => "zh-TW,ja;q=0.8" }
    assert_select "html[lang='zh-CN']"

    get new_session_path(locale: "ja"), headers: { "Accept-Language" => "zh-CN" }
    assert_select "html[lang='ja']"
    raw_cookie = cookies[:locale]
    assert raw_cookie.present?
    assert_not_equal "ja", raw_cookie

    get new_registration_path, headers: { "Accept-Language" => "zh-CN" }
    assert_select "html[lang='ja']"
  end

  test "invalid registration preserves normalized email but never password and writes nothing" do
    email = flow_email("invalid")
    track_flow_ip

    assert_no_difference [ "User.count", "VerificationSendAttempt.count", "EmailVerificationToken.count" ] do
      post registration_path, params: {
        user: { email_address: "  #{email.upcase} ", password: "short", password_confirmation: "different" }
      }
    end

    assert_response :unprocessable_content
    email_field = css_select("input[type='email']").sole
    assert_equal email, email_field["value"]
    assert_select "input[type=password][value]", count: 0
    assert_not_includes response.body, "short"
    assert_not_includes response.body, "different"
  end

  test "registration creates an unverified account and duplicate registration never resends" do
    email = flow_email("registration")

    assert_difference [ "User.count", "EmailVerificationToken.count", "VerificationSendAttempt.count" ], 1 do
      post registration_path, params: {
        user: {
          email_address: email, password: AccountTestSupport::PASSWORD,
          password_confirmation: AccountTestSupport::PASSWORD
        }
      }
    end

    assert_redirected_to verification_email_path
    user = User.find_by!(email_address: email)
    assert_not user.email_verified?
    assert_empty user.sessions
    assert_enqueued_jobs 1, only: EmailVerificationDeliveryJob
    secret = latest_verification_secret
    assert_not_includes response.location, email
    assert_not_includes response.location, secret

    clear_enqueued_jobs
    assert_no_difference [ "User.count", "EmailVerificationToken.count", "VerificationSendAttempt.count" ] do
      post registration_path, params: {
        user: {
          email_address: email.upcase, password: AccountTestSupport::PASSWORD,
          password_confirmation: AccountTestSupport::PASSWORD
        }
      }
    end
    assert_redirected_to verification_email_path
    assert_no_enqueued_jobs
  end

  test "unknown verified and unverified resend requests expose the same accepted page" do
    track_flow_ip
    unverified = create_flow_user
    verified = create_flow_user(email_verified_at: Time.current)
    unknown = flow_email("unknown")
    bodies = []

    [ unverified.email_address, verified.email_address, unknown ].each do |email|
      post verification_email_path, params: { email_address: email }
      assert_redirected_to verification_email_path
      follow_redirect!
      assert_response :ok
      bodies << response.body.gsub(/authenticity_token[^>]+/, "authenticity_token")
    end

    bodies.each { |body| assert_includes body, I18n.t("account_flow.verification_email.results.accepted.title", locale: :ja) }
    assert_equal 1, unverified.email_verification_tokens.count
    assert_empty verified.email_verification_tokens
    assert_equal 1, EmailVerificationToken.joins(:user).where(users: { email_address: @flow_emails }).count
  end

  test "verification GET is read only and POST verifies once without logging in" do
    user = create_flow_user
    EmailVerificationIssuer.issue(user_id: user.id, locale: :ja)
    secret = latest_verification_secret
    token = user.email_verification_tokens.sole

    assert_no_changes -> { user.reload.email_verified_at } do
      assert_no_changes -> { token.reload.invalidation_reason } do
        get email_verification_path(token: secret)
      end
    end
    assert_response :ok
    assert_select "form[action=?][method=post]", email_verification_path
    assert_includes response.body, "***@example.test"

    post email_verification_path, params: { token: secret }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_response :ok
    assert_select "[role=status]", text: I18n.t("account_flow.login.verification_success", locale: :ja)
    assert user.reload.email_verified?
    assert_equal "consumed", token.reload.invalidation_reason
    assert_empty user.sessions
    assert_nil cookies[:session_id]

    post email_verification_path, params: { token: secret }
    assert_redirected_to email_verification_path
    follow_redirect!
    assert_response :ok
    assert_select "h1", text: I18n.t("account_flow.email_verification.results.consumed.title", locale: :ja)
  end

  test "login uses generic failure distinguishes verified eligibility and creates no automatic session" do
    verified = create_flow_user(email_verified_at: Time.current)
    unverified = create_flow_user

    assert_no_difference "Session.count" do
      post session_path, params: { email_address: "missing@example.test", password: AccountTestSupport::PASSWORD }
      assert_response :unprocessable_content
      assert_includes response.body, I18n.t("account_flow.login.errors.invalid_credentials", locale: :ja)
    end
    assert_no_difference "Session.count" do
      post session_path, params: { email_address: unverified.email_address, password: AccountTestSupport::PASSWORD }
      assert_response :unprocessable_content
      assert_includes response.body, I18n.t("account_flow.login.errors.unverified", locale: :ja)
    end

    post session_path, params: { email_address: verified.email_address, password: AccountTestSupport::PASSWORD }
    assert_redirected_to observations_path
    assert_equal 1, verified.sessions.count
    assert cookies[:session_id].present?
  end

  test "formal mutation endpoints reject missing CSRF tokens" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    email = flow_email("csrf")
    track_flow_ip

    assert_no_difference [ "User.count", "VerificationSendAttempt.count", "Session.count" ] do
      post registration_path, params: {
        user: {
          email_address: email, password: AccountTestSupport::PASSWORD,
          password_confirmation: AccountTestSupport::PASSWORD
        }
      }
    end
    assert_response :unprocessable_content

    post verification_email_path, params: { email_address: email }
    assert_response :unprocessable_content
    post session_path, params: { email_address: email, password: AccountTestSupport::PASSWORD }
    assert_response :unprocessable_content
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  test "logout deletes only the current database session" do
    user = create_flow_user(email_verified_at: Time.current)
    other = login(user).session
    post session_path, params: { email_address: user.email_address, password: AccountTestSupport::PASSWORD }
    current_id = user.sessions.where.not(id: other.id).sole.id

    delete session_path

    assert_redirected_to new_session_path
    assert_not Session.exists?(current_id)
    assert Session.exists?(other.id)
    assert cookies[:session_id].blank?
  end
end
