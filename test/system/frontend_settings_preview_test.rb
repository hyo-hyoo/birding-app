require "application_system_test_case"

class FrontendSettingsPreviewTest < ApplicationSystemTestCase
  test "switches language and closes the settings navigation loop" do
    visit frontend_preview_history_path(locale: "zh-CN")

    within ".bottom-nav" do
      click_link "设置"
    end

    assert_current_path frontend_preview_settings_path(locale: "zh-CN")
    assert_text "你的观察环境"
    assert_selector ".language-choice .choice-chip[aria-current='page']", text: "简体中文"

    within ".language-choice" do
      click_link "日本語"
    end

    assert_current_path frontend_preview_settings_path(locale: "ja")
    assert_text "観察環境の設定"
    assert_selector ".language-choice .choice-chip[aria-current='page']", text: "日本語"

    click_link "パスワードを変更"

    assert_current_path frontend_preview_change_password_path(locale: "ja")
    assert_text "現在のパスワード"
    assert_no_selector ".bottom-nav"

    fill_in "現在のパスワード", with: "current-password"
    fill_in "新しいパスワード", with: "new-password"
    fill_in "新しいパスワードを確認", with: "new-password"
    click_link "新しいパスワードを保存"

    assert_current_path frontend_preview_settings_path(locale: "ja")

    within ".bottom-nav" do
      click_link "観察履歴"
    end

    assert_current_path frontend_preview_history_path(locale: "ja")

    within ".bottom-nav" do
      click_link "設定"
    end
    click_link "ログアウト"

    assert_current_path frontend_preview_login_path(locale: "ja")
    assert_text "おかえりなさい"
  end
end
