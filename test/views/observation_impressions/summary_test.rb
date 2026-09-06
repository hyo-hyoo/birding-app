require "test_helper"

class ObservationImpressionSummaryViewTest < ActionView::TestCase
  test "escapes free text while preserving the complete summary content" do
    description = "<strong>bright</strong> & " + ("detail " * 40).strip
    impression = ObservationImpression.new(
      outline_key: "anatidae",
      parts: {
        head: {
          primary_color_key: "green",
          description:,
          certainty_key: "certain"
        }
      }
    )
    summary = ObservationSummary.new(impression, locale: :"zh-CN")

    render partial: "observation_impressions/summary", locals: { summary: }

    assert_includes rendered, "&lt;strong&gt;bright&lt;/strong&gt; &amp;"
    assert_not_includes rendered, "<strong>bright</strong>"
    assert_includes rendered, "detail " * 39
  end
end
