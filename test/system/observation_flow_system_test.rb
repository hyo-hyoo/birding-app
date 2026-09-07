require "application_system_test_case"
require_relative "../support/account_test_support"

class ObservationFlowSystemTest < ApplicationSystemTestCase
  include AccountTestSupport

  setup do
    @user = create_user(email_verified_at: Time.current)
  end

  teardown do
    ids = Observation.where(user_id: @user.id).pluck(:id)
    ActivityLocationSelection.where(observation_id: ids).delete_all
    PartImpression.where(observation_id: ids).delete_all
    Observation.where(id: ids).delete_all
    Session.where(user_id: @user.id).delete_all
    User.where(id: @user.id).delete_all
  end

  test "selects an approved outline protects unsaved input and saves a real observation" do
    visit new_session_path(locale: "zh-CN")
    fill_in "邮箱", with: @user.email_address
    fill_in "密码", with: PASSWORD
    click_button "登录"

    assert_text "这里还没有观察"
    click_link "记录新的观察"
    assert_text "选择接近的轮廓"

    click_button I18n.t!("observation_options.outline_groups.water_surface", locale: :"zh-CN")
    click_button I18n.t!("observation_options.outlines.anatidae", locale: :"zh-CN")
    click_button "使用这个轮廓继续"

    assert_text "记录记得的特征"
    assert_selector "#observation-impression-preview .observation-impression-svg", count: 1
    assert_button "保存这次观察", disabled: true
    within first("fieldset", text: "主颜色") do
      find("label", text: I18n.t!("observation_options.colors.black", locale: :"zh-CN")).click
    end
    assert_selector "[data-impression-part='head'] .observation-impression__part[fill='#252729']"
    within first("fieldset", text: "补充色") do
      find("label", text: I18n.t!("observation_options.colors.white", locale: :"zh-CN")).click
    end
    within first("fieldset", text: "花纹或特征") do
      find("label", text: I18n.t!("observation_options.features.eye_ring", locale: :"zh-CN")).click
    end
    assert_selector "#observation-impression-preview [data-secondary-for='head']"
    assert_button "保存这次观察", disabled: true
    within first("fieldset", text: "确定程度") do
      find("label", text: I18n.t!("observation_options.certainties.certain", locale: :"zh-CN")).click
    end
    fill_in "observation-part-head-description", with: "眼睛周围很亮"
    within "#observation-impression-preview" do
      assert_text "眼睛周围很亮"
    end

    click_button "← 返回"
    assert_selector "dialog[open]"
    assert_text "还有尚未保存的修改"
    click_button "继续编辑"
    assert_no_selector "dialog[open]"

    find("label", text: I18n.t!("observation_options.activity_locations.water_surface", locale: :"zh-CN")).click
    find("label", text: I18n.t!("observation_options.activity_locations.shallow_water", locale: :"zh-CN")).click
    find("label", text: I18n.t!("observation_options.activity_locations.waterside", locale: :"zh-CN")).click
    assert_text "行动位置最多选择两个"
    assert_selector "#observation-location-water_surface:checked", visible: :all
    assert_selector "#observation-location-shallow_water:checked", visible: :all
    assert_selector "#observation-location-waterside:not(:checked)", visible: :all
    fill_in "observation-behavior", with: "缓慢游动"
    click_button "保存这次观察"

    assert_current_path %r{\A/observations/\d+\z}
    observation = @user.observations.reload.sole
    assert_current_path observation_path(observation)
    assert_text "眼睛周围很亮"
    assert_selector ".detail-hero .observation-impression-svg", count: 1
    assert_selector ".observation-summary__list", count: 1
    assert_text "缓慢游动"
    assert_text I18n.t!("observation_options.activity_locations.water_surface", locale: :"zh-CN")

    click_link "观察历史"
    assert_selector ".record-card", count: 1
    assert_selector ".record-card .observation-impression-svg", count: 1
    assert_text "已记录 1 个部位"
  end

  test "keeps the latest rapid preview and recovers safely from network and session failure" do
    visit new_session_path(locale: "zh-CN")
    fill_in "邮箱", with: @user.email_address
    fill_in "密码", with: PASSWORD
    click_button "登录"
    assert_text "这里还没有观察"
    visit new_observation_path(outline_key: "compact_passerine", locale: "zh-CN")

    page.execute_script(<<~JAVASCRIPT)
      ["black", "red", "green"].forEach((color) => {
        document.querySelector(`input[name="observation[parts][head][primary_color_key]"][value="${color}"]`).click()
      })
    JAVASCRIPT
    assert_selector "[data-impression-part='head'] .observation-impression__part[fill='#5E7B4D']"

    page.execute_script("window.stage8OriginalFetch = window.fetch; window.fetch = () => Promise.reject(new Error('offline'))")
    fill_in "observation-part-head-description", with: "网络失败时仍需保留"
    assert_text "预览暂时无法更新"
    assert_field "observation-part-head-description", with: "网络失败时仍需保留"

    page.execute_script("window.fetch = window.stage8OriginalFetch")
    Session.where(user_id: @user.id).delete_all
    within first("fieldset", text: "主颜色") do
      find("label", text: I18n.t!("observation_options.colors.blue", locale: :"zh-CN")).click
    end
    assert_current_path new_session_path
  end
end
