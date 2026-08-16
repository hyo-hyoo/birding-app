require "application_system_test_case"

class FrontendDetailPreviewTest < ApplicationSystemTestCase
  test "applies reversible identification actions immediately and saves candidate deletion" do
    visit frontend_preview_detail_path(locale: "zh-CN", state: "candidate")

    assert_text "候选中"
    assert_text "2 / 3"
    assert_no_selector "[data-identification-target='saveBar']", visible: true

    find("button[aria-label='选择候选 黄腹山雀']").click
    assert_no_selector "[data-identification-target='saveBar']", visible: true

    click_button "将所选候选设为最终鸟名"
    assert_text "已确认"
    assert_selector "h1", text: "黄腹山雀"
    assert_text "已将“黄腹山雀”设为最终鸟名"
    assert_no_selector "[data-identification-target='saveBar']", visible: true
    assert_no_selector "[data-identification-target='statusUnsaved']", visible: true
    assert_selector "button[data-identification-target='candidateToggle'][aria-expanded='false']", visible: true
    assert_no_selector "[data-identification-target='candidatePanel']", visible: true

    click_button "候选鸟名"
    assert_selector "button[data-identification-target='candidateToggle'][aria-expanded='true']", visible: true
    assert_selector "[data-identification-target='candidatePanel']", visible: true

    click_button "撤销确认"
    assert_text "候选中"
    assert_text "已撤销最终确认"
    assert_no_selector "[data-identification-target='saveBar']", visible: true
    assert_selector "[data-identification-target='candidatePanel']", visible: true

    fill_in "输入候选鸟名", with: "白腹蓝鹟"
    click_button "＋ 添加"
    assert_text "已添加候选"
    assert_text "3 / 3"
    assert_no_selector "[data-identification-target='saveBar']", visible: true

    find("button[aria-label='删除候选 远东山雀']").click
    assert_text "已移除候选，尚未保存"
    assert_selector "[data-identification-target='statusUnsaved']", text: "未保存"
    assert_button "保存识别修改"

    click_button "保存识别修改"
    assert_text "待保存的识别修改已保存"
    assert_no_selector "[data-identification-target='saveBar']", visible: true
    assert_no_selector "[data-identification-target='statusUnsaved']", visible: true
    assert_button "＋ 添加", disabled: false
  end

  test "saves final-name replacement and retains a non-candidate name when revoking" do
    visit frontend_preview_detail_path(locale: "ja", state: "pending")

    assert_text "未確認"
    click_button "別の鳥名を入力"
    fill_in "別の最終鳥名", with: "メジロ"
    click_button "最終鳥名にする"

    assert_text "確認済み"
    assert_selector "h1", text: "メジロ"
    assert_no_selector "[data-identification-target='saveBar']", visible: true
    assert_selector "button[data-identification-target='candidateToggle'][aria-expanded='false']", visible: true

    click_button "変更"
    assert_no_text "現在の最終鳥名"
    fill_in "最終鳥名を変更", with: "ウグイス"
    assert_selector "h1", text: "ウグイス"
    assert_button "識別情報を保存"

    click_button "識別情報を保存"
    assert_text "現在の最終鳥名"
    assert_text "ウグイス"
    assert_no_field "最終鳥名を変更", visible: true

    click_button "確認を取り消す"
    assert_selector "dialog[open]"
    assert_text "現在の最終鳥名「ウグイス」は候補にありません"
    click_button "候補に残して取り消す"

    assert_text "候補あり"
    assert_text "最終確認を取り消し、「ウグイス」を候補に残しました"
    assert_text "1 / 3"
    assert_no_selector "[data-identification-target='saveBar']", visible: true
  end

  test "asks which candidate to replace when revoking with a full candidate list" do
    visit frontend_preview_detail_path(locale: "zh-CN", state: "candidate")

    fill_in "输入候选鸟名", with: "白腹蓝鹟"
    click_button "＋ 添加"
    click_button "输入其他鸟名"
    fill_in "其他最终鸟名", with: "大山雀"
    click_button "设为最终鸟名"
    click_button "撤销确认"

    assert_selector "dialog[open]"
    assert_text "候选已满，请选择一个要替换的候选"
    assert_button "替换并撤销", disabled: true
    find("label.revoke-candidate-option", text: "黄腹山雀").click
    assert_button "替换并撤销", disabled: false
    click_button "替换并撤销"

    assert_text "候选中"
    assert_text "已用“大山雀”替换候选“黄腹山雀”"
    assert_text "远东山雀"
    assert_text "白腹蓝鹟"
    assert_text "大山雀"
    within "[data-identification-target='candidateList']" do
      assert_no_text "黄腹山雀"
    end
    assert_no_selector "[data-identification-target='saveBar']", visible: true
  end

  test "allows an explicit revoke without retaining a non-candidate name" do
    visit frontend_preview_detail_path(locale: "zh-CN", state: "pending")
    click_button "输入其他鸟名"
    fill_in "其他最终鸟名", with: "大山雀"
    click_button "设为最终鸟名"
    click_button "撤销确认"
    click_button "仅撤销，不保留"

    assert_text "待确认"
    assert_text "已撤销最终确认"
    assert_text "0 / 3"
    assert_no_text "大山雀"
    assert_no_selector "[data-identification-target='saveBar']", visible: true
  end

  test "protects unsubmitted bird names before leaving" do
    visit frontend_preview_detail_path(locale: "zh-CN", state: "candidate")
    fill_in "输入候选鸟名", with: "白腹"

    click_link "← 历史"
    assert_selector "dialog[open]"
    assert_text "鸟名还没有提交"
    click_button "继续输入"
    assert_field "输入候选鸟名", with: "白腹", focused: true

    click_link "← 历史"
    click_button "放弃输入并离开"
    assert_current_path frontend_preview_history_path(locale: "zh-CN")

    visit frontend_preview_detail_path(locale: "zh-CN", state: "pending")
    click_button "输入其他鸟名"
    fill_in "其他最终鸟名", with: "大山"
    click_link "编辑记录"
    assert_selector "dialog[open]"
    assert_text "鸟名还没有提交"
    click_button "放弃输入并离开"
    assert_current_path frontend_preview_editor_path(locale: "zh-CN")
  end

  test "handles unsubmitted text before other unsaved changes" do
    visit frontend_preview_detail_path(locale: "zh-CN", state: "candidate")
    find("button[aria-label='删除候选 远东山雀']").click
    fill_in "输入候选鸟名", with: "白腹"

    click_link "← 历史"
    assert_text "鸟名还没有提交"
    click_button "放弃输入并离开"

    assert_selector "dialog[open]"
    assert_text "识别信息还没有保存"
    click_button "继续编辑"
    assert_current_path frontend_preview_detail_path(locale: "zh-CN", state: "candidate")
    assert_field "输入候选鸟名", with: ""
    assert_selector "[data-identification-target='statusUnsaved']", text: "未保存"
  end

  test "only protects departures when saved identification data can be lost" do
    visit frontend_preview_detail_path(locale: "zh-CN", state: "candidate")
    click_button "将所选候选设为最终鸟名"
    click_link "← 历史"
    assert_current_path frontend_preview_history_path(locale: "zh-CN")

    visit frontend_preview_detail_path(locale: "zh-CN", state: "candidate")
    find("button[aria-label='删除候选 远东山雀']").click

    click_link "← 历史"
    assert_selector "dialog[open]"
    assert_text "识别信息还没有保存"
    click_button "继续编辑"
    assert_current_path frontend_preview_detail_path(locale: "zh-CN", state: "candidate")

    within "nav.bottom-nav" do
      click_link "新建观察"
    end
    assert_selector "dialog[open]"
    click_button "继续编辑"

    click_link "← 历史"
    click_button "保存并离开"
    assert_current_path frontend_preview_history_path(locale: "zh-CN")

    visit frontend_preview_detail_path(locale: "zh-CN", state: "confirmed")
    click_button "修改"
    fill_in "修改最终鸟名", with: "大山雀"
    click_link "编辑记录"
    assert_selector "dialog[open]"
    click_button "放弃修改并离开"
    assert_current_path frontend_preview_editor_path(locale: "zh-CN")
  end
end
