require "application_system_test_case"

class FrontendQualityPreviewTest < ApplicationSystemTestCase
  PREVIEW_CASES = [
    [ :frontend_preview_login_path, {} ],
    [ :frontend_preview_register_path, {} ],
    [ :frontend_preview_verification_sent_path, {} ],
    [ :frontend_preview_verification_success_path, {} ],
    [ :frontend_preview_reset_request_path, {} ],
    [ :frontend_preview_reset_password_path, {} ],
    [ :frontend_preview_reset_success_path, {} ],
    [ :frontend_preview_history_empty_path, {} ],
    [ :frontend_preview_history_path, {} ],
    [ :frontend_preview_outline_path, {} ],
    [ :frontend_preview_editor_path, {} ],
    [ :frontend_preview_detail_path, { state: "confirmed" } ],
    [ :frontend_preview_settings_path, {} ],
    [ :frontend_preview_change_password_path, {} ]
  ].freeze

  VIEWPORTS = [
    [ 320, 844 ],
    [ 390, 844 ],
    [ 1440, 900 ]
  ].freeze

  teardown do
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  test "renders every Japanese preview without horizontal overflow at target widths" do
    VIEWPORTS.each do |width, height|
      emulate_viewport(width, height)

      PREVIEW_CASES.each do |path_helper, options|
        visit public_send(path_helper, **options, locale: "ja")

        assert_selector ".app-page"
        assert_equal width, page.evaluate_script("window.innerWidth")
        assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, width,
          "Expected #{path_helper} to fit within #{width}px"
      end
    end
  end

  test "exposes representative account errors without relying on color alone" do
    emulate_viewport(390, 844)
    visit frontend_preview_login_path(locale: "zh-CN", state: "invalid_credentials")

    assert_selector "#login-credentials-error[role='alert']", text: "邮箱或密码不正确，请重新输入。"
    assert_selector "#login-email[aria-invalid='true']"
    assert_selector "#login-password[aria-invalid='true']"

    find("#login-email").click
    find("#login-email").send_keys(:tab)
    assert_equal "login-password", page.evaluate_script("document.activeElement.id")

    visit frontend_preview_register_path(locale: "ja", state: "password_mismatch")

    assert_selector "#register-password-error[role='alert']", text: "入力したパスワードが一致しません。"
    assert_no_selector "#register-password[aria-invalid]"
    assert_selector "#register-password-confirmation[aria-invalid='true']"
  end

  test "keeps fixed actions visible in a short mobile viewport" do
    emulate_viewport(390, 500)
    visit frontend_preview_editor_path(locale: "zh-CN")

    save_bar = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const rect = document.querySelector('.editor-dock').getBoundingClientRect();
        return { top: rect.top, bottom: rect.bottom, viewport: window.innerHeight };
      })()
    JAVASCRIPT

    assert_operator save_bar["top"], :>=, 0
    assert_operator save_bar["bottom"], :<=, save_bar["viewport"]

    visit frontend_preview_detail_path(locale: "zh-CN", state: "confirmed")

    bottom_nav = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const rect = document.querySelector('.bottom-nav').getBoundingClientRect();
        return { top: rect.top, bottom: rect.bottom, viewport: window.innerHeight };
      })()
    JAVASCRIPT

    assert_operator bottom_nav["top"], :>=, 0
    assert_operator bottom_nav["bottom"], :<=, bottom_nav["viewport"]
    assert_operator page.evaluate_script("document.querySelector('.detail-edit-link').getBoundingClientRect().height"), :>=, 44
  end


  private

  def emulate_viewport(width, height)
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width: width,
      height: height,
      deviceScaleFactor: 1,
      mobile: width <= 390
    )
  end
end
