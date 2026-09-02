require "application_system_test_case"
require "uri"
require_relative "../support/account_flow_test_support"

class AccountFlowSystemTest < ApplicationSystemTestCase
  include AccountFlowTestSupport

  setup :setup_account_flow
  teardown :teardown_account_flow

  test "register verify log in change browser locale and log out" do
    email = flow_email("system")

    visit new_registration_path(locale: "zh-CN")
    fill_in "邮箱", with: email
    fill_in "密码", with: AccountTestSupport::PASSWORD
    fill_in "确认密码", with: AccountTestSupport::PASSWORD
    click_button "创建账户"

    assert_text "账户已创建"
    user = User.find_by!(email_address: email)
    assert_not user.email_verified?
    assert_empty user.sessions

    perform_enqueued_jobs(only: EmailVerificationDeliveryJob)
    mail = ActionMailer::Base.deliveries.sole
    verification_uri = URI(Nokogiri::HTML(mail.html_part.body.to_s).at_css("a")["href"])

    visit verification_uri.request_uri
    assert_text "确认你的邮箱"
    assert_not user.reload.email_verified?
    click_button "确认这是我的邮箱"

    assert_current_path new_session_path
    assert_text "邮箱验证成功"
    assert user.reload.email_verified?
    assert_empty user.sessions

    fill_in "邮箱", with: email
    fill_in "密码", with: AccountTestSupport::PASSWORD
    click_button "登录"

    assert_text I18n.t("frontend_previews.history_empty.title", locale: :"zh-CN")
    assert_equal 1, user.sessions.count
    click_link "设置"
    assert_text email

    click_link "日本語"
    assert_selector "html[lang='ja']"
    click_button "ログアウト"

    assert_text "おかえりなさい"
    assert_empty user.sessions.reload
    assert_selector "html[lang='ja']"
  end
end
