require "test_helper"

class FrontendPreviewsTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  PREVIEW_PAGES = %i[
    frontend_preview_login_path
    frontend_preview_register_path
    frontend_preview_verification_sent_path
    frontend_preview_verification_success_path
    frontend_preview_reset_request_path
    frontend_preview_reset_password_path
    frontend_preview_reset_success_path
    frontend_preview_history_empty_path
    frontend_preview_history_path
    frontend_preview_outline_path
    frontend_preview_editor_path
  ].freeze
  PREVIEW_LOCALES = %w[zh-CN ja].freeze

  test "renders every static preview in both supported languages" do
    PREVIEW_PAGES.product(PREVIEW_LOCALES).each do |path_helper, locale|
      get public_send(path_helper, locale: locale)

      assert_response :success
      assert_select "html[lang='#{locale}']", count: 1
      assert_select "h1", count: 1
      assert_select "title", text: /\S+/
      assert_no_match(/translation missing/, response.body)
    end
  end

  test "keeps account forms and controls explicitly static" do
    %i[
      frontend_preview_login_path
      frontend_preview_register_path
      frontend_preview_reset_request_path
      frontend_preview_reset_password_path
    ].each do |path_helper|
      get public_send(path_helper, locale: "zh-CN")

      assert_select "form[data-static-preview='true']", count: 1
      assert_select "form[data-static-preview='true'][action]", count: 0
      assert_select "form[data-static-preview='true'] button:not([type='button'])", count: 0
      assert_select "a[href='#']", count: 0
    end

    %i[frontend_preview_login_path frontend_preview_register_path].each do |path_helper|
      get public_send(path_helper, locale: "zh-CN")

      assert_select "details.language-switcher", count: 1
      assert_select ".language-switcher__option[aria-current='page']", count: 1
    end
  end

  test "connects the static first-slice preview flow" do
    get frontend_preview_login_path(locale: "zh-CN")
    assert_select "a[href='#{frontend_preview_register_path(locale: "zh-CN")}']"
    assert_select "a[href='#{frontend_preview_reset_request_path(locale: "zh-CN")}']"
    assert_select "a[href='#{frontend_preview_history_empty_path(locale: "zh-CN")}']"

    get frontend_preview_register_path(locale: "zh-CN")
    assert_select "a[href='#{frontend_preview_verification_sent_path(locale: "zh-CN")}']"

    get frontend_preview_verification_sent_path(locale: "zh-CN")
    assert_select "a[href='#{frontend_preview_verification_success_path(locale: "zh-CN")}']"
    assert_select ".notice", count: 1

    get frontend_preview_verification_success_path(locale: "zh-CN")
    assert_select "a[href='#{frontend_preview_login_path(locale: "zh-CN")}']"
  end

  test "connects the static password reset preview flow" do
    get frontend_preview_reset_request_path(locale: "zh-CN")
    assert_select "a[href='#{frontend_preview_login_path(locale: "zh-CN")}']"
    assert_select "a[href='#{frontend_preview_reset_password_path(locale: "zh-CN")}']"
    assert_select ".form-help", text: /相同的发送结果/

    get frontend_preview_reset_password_path(locale: "zh-CN")
    assert_select "input[autocomplete='new-password']", count: 2
    assert_select "a[href='#{frontend_preview_reset_success_path(locale: "zh-CN")}']"

    get frontend_preview_reset_success_path(locale: "zh-CN")
    assert_select ".result-card", count: 1
    assert_select "a[href='#{frontend_preview_login_path(locale: "zh-CN")}']"
  end

  test "renders the empty history hierarchy and links to a new observation" do
    get frontend_preview_history_empty_path(locale: "zh-CN")

    assert_select "main h2", count: 1
    assert_select ".bottom-nav__item", count: 3
    assert_select ".bottom-nav__item.is-active", count: 1
    assert_select "button.bottom-nav__item[aria-disabled='true']", count: 1
    assert_select "a[href='#{frontend_preview_outline_path(locale: "zh-CN")}']", count: 2
  end

  test "renders the non-empty history with derived identification states" do
    get frontend_preview_history_path(locale: "zh-CN")

    assert_response :success
    assert_select ".record-card", count: 3
    assert_select ".bird-thumbnail[role='img']", count: 3
    assert_select ".record-card--pending .status-pill", text: "待确认", count: 1
    assert_select ".record-card--candidate .status-pill", text: "候选中", count: 1
    assert_select ".record-card--candidate h3", count: 0
    assert_select ".record-card--confirmed .status-pill", text: "已确认", count: 1
    assert_select ".record-card--confirmed h3", text: "白鹡鸰", count: 1
    assert_select ".bottom-nav__item", count: 3
    assert_select ".bottom-nav__item.is-active", count: 1
    assert_select "button.bottom-nav__item[aria-disabled='true']", count: 1
    assert_select "a[href='#{frontend_preview_outline_path(locale: "zh-CN")}']", count: 2
    assert_select "a[href='#']", count: 0
  end

  test "renders the two-stage outline selector without future navigation" do
    get frontend_preview_outline_path(locale: "zh-CN")

    assert_response :success
    assert_select "[data-controller='outline-selection']", count: 1
    assert_select ".group-card[aria-pressed='false']", count: 4
    assert_select ".shape-card[aria-pressed='false']", count: 4
    assert_select ".fallback-card[aria-pressed='false']", count: 1
    assert_select "[data-outline-selection-target='shapesStage'][hidden]", count: 1
    assert_select "button[data-outline-selection-target='continue'][disabled][aria-disabled='true']", count: 1
    assert_select ".bottom-nav", count: 0
    assert_select "script[type='importmap']", count: 1
    assert_select "a[href='#{frontend_preview_history_path(locale: "zh-CN")}']", count: 1
    assert_select "[data-outline-selection-editor-url-value='#{frontend_preview_editor_path(locale: "zh-CN")}']", count: 1
    assert_select "a[href='#']", count: 0
  end

  test "renders the observation editor with static save constraints" do
    get frontend_preview_editor_path(locale: "zh-CN")

    assert_response :success
    assert_select "[data-controller='observation-editor']", count: 1
    assert_select ".impression-bird[role='img']", count: 1
    assert_select "[data-observation-editor-target='partGraphic']", count: 4
    assert_select ".part-tab[role='tab']", count: 4
    assert_select ".part-tab.is-active[aria-selected='true']", text: "头部", count: 1
    assert_select "[data-observation-editor-target='primaryChoice']", count: 6
    assert_select "[data-observation-editor-target='secondaryChoice']", count: 6
    assert_select "[data-observation-editor-target='featureChoice']", count: 4
    assert_select "[data-observation-editor-target='certaintyChoice']", count: 3
    assert_select "[data-observation-editor-target='locationChoice']", count: 4
    assert_select "button[data-observation-editor-target='save'][disabled][aria-disabled='true']", count: 1
    assert_select "dialog.confirm-dialog", count: 1
    assert_select ".bottom-nav", count: 0
    assert_select "a[href='#']", count: 0
  end

  test "falls back to Japanese for an unsupported preview locale" do
    get frontend_preview_login_path(locale: "unsupported")

    assert_response :success
    assert_select "html[lang='ja']", count: 1
    assert_select "h1", text: "おかえりなさい"
  end
end
