require "application_system_test_case"

class FrontendOutlinePreviewTest < ApplicationSystemTestCase
  test "selects a group, a specific outline, and the fallback outline" do
    visit frontend_preview_outline_path(locale: "zh-CN")

    assert_text "它大概是什么体型？"
    assert_selector "[data-outline-selection-target='groupsStage']:not([hidden])"

    click_button "圆润短身"

    assert_selector "[data-outline-selection-target='shapesStage']:not([hidden])"
    assert_text "选择具体轮廓"
    assert_button "使用这个轮廓", disabled: true

    click_button "轮廓示例 02"

    assert_selector ".shape-card.is-selected[aria-pressed='true']", text: "轮廓示例 02"
    assert_button "使用这个轮廓", disabled: false

    click_button "使用这个轮廓"

    assert_current_path frontend_preview_editor_path(locale: "zh-CN")
    assert_text "记录这只鸟"

    visit frontend_preview_outline_path(locale: "zh-CN")

    click_button "水边低身"
    click_button "没有合适的轮廓"

    assert_selector ".fallback-card.is-selected[aria-pressed='true']"
    assert_button "使用这个轮廓", disabled: false
  end
end
