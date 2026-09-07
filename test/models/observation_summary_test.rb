require "test_helper"

class ObservationSummaryTest < ActiveSupport::TestCase
  test "generates complete localized summaries in canonical part order" do
    note = "a complete note <strong>that must remain text</strong> " + ("detail " * 40)
    impression = ObservationImpression.new(
      outline_key: "compact_passerine",
      parts: {
        tail: { primary_color_key: "blue_gray", feature_key: "long_tail", description: note, certainty_key: "vague" },
        head: { primary_color_key: "black", secondary_color_key: "white", feature_key: "cheek_patch", certainty_key: "certain" }
      }
    )

    chinese = ObservationSummary.new(impression, locale: :"zh-CN")
    japanese = ObservationSummary.new(impression, locale: :ja)

    assert_equal %w[head tail], chinese.items.map(&:part_key)
    assert_includes chinese.items.first.details, "主色：黑色"
    assert_includes chinese.items.first.details, "补充色：白色"
    assert_includes chinese.items.first.details, "特征：颊斑"
    assert_equal "确定", chinese.items.first.certainty_label
    assert_includes chinese.items.last.details, "补充：#{note.strip}"
    assert_includes japanese.items.first.details, "特徴：頬斑"
    assert_equal "とても曖昧", japanese.items.last.certainty_label
  end

  test "marks missing certainty without removing a safe incomplete part" do
    impression = ObservationImpression.new(outline_key: "anatidae", parts: { chest_belly: { description: "visible" } })
    summary = ObservationSummary.new(impression, locale: :"zh-CN")

    assert_equal "尚未选择", summary.items.first.certainty_label
    assert_includes summary.items.first.details, "补充：visible"
  end

  test "keeps crest forked tail and long tail in localized text summaries" do
    [
      [ "head", "crest", "冠羽", "冠羽" ],
      [ "tail", "forked_tail", "叉尾", "燕尾（二又）" ],
      [ "tail", "long_tail", "长尾", "長い尾" ]
    ].each do |part_key, feature_key, chinese_label, japanese_label|
      impression = ObservationImpression.new(
        outline_key: "compact_passerine",
        parts: { part_key => { feature_key:, certainty_key: "certain" } }
      )

      assert_includes ObservationSummary.new(impression, locale: :"zh-CN").items.first.details, "特征：#{chinese_label}"
      assert_includes ObservationSummary.new(impression, locale: :ja).items.first.details, "特徴：#{japanese_label}"
    end
  end
end
