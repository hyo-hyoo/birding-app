require "application_system_test_case"

class FrontendEditorPreviewTest < ApplicationSystemTestCase
  test "records part impressions and protects unsaved changes" do
    visit frontend_preview_editor_path(locale: "zh-CN")

    assert_text "记录这只鸟"
    assert_selector ".part-tab.is-active[aria-selected='true']", text: "头部"
    assert_button "保存这次观察", disabled: true
    assert_text "尚未记录身体部位"

    within "[aria-label='主颜色']" do
      find("button[aria-label='黄色']").click
    end

    assert_button "保存这次观察", disabled: true
    assert_text "请为每个已记录部位选择确定程度"

    within "[aria-label='确定程度']" do
      click_button "大概如此"
    end

    assert_button "保存这次观察", disabled: false
    assert_selector ".part-tab.is-set", text: "头部"
    assert_text "头部：主色 黄色；大概如此。"
    assert_selector "[data-observation-editor-target='partGraphic'][data-part-key='head'][fill='#e6c65f']"

    click_button "胸腹"
    within "[aria-label='主颜色']" do
      find("button[aria-label='蓝灰']").click
    end
    within "[aria-label='花纹或特征']" do
      click_button "细条纹"
    end
    within "[aria-label='确定程度']" do
      click_button "非常模糊"
    end
    fill_in "补充看见的细节", with: "腹部中央更浅"

    assert_selector ".part-tab.is-set", text: "胸腹"
    assert_text "胸腹：主色 蓝灰、特征 细条纹、补充：腹部中央更浅；非常模糊。"

    click_button "头部"
    within "[aria-label='主颜色']" do
      assert_selector "button[aria-label='黄色'][aria-pressed='true']"
    end

    within "[aria-label='行动位置']" do
      click_button "树上"
      click_button "地面"
      click_button "水边"
      assert_selector "button[aria-pressed='true']", text: "树上"
      assert_selector "button[aria-pressed='true']", text: "地面"
      assert_selector "button[aria-pressed='false']", text: "水边"
    end
    assert_text "行动位置最多选择两个"

    click_button "← 修改轮廓"
    assert_selector "dialog[open]"
    assert_text "要放弃这次修改吗？"
    click_button "继续编辑"
    assert_no_selector "dialog[open]"

    click_button "保存这次观察"
    assert_current_path frontend_preview_detail_path(locale: "zh-CN", state: "candidate")
    assert_text "候选中"
  end
end
