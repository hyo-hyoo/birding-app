require "test_helper"

class ObservationVisualRendererTest < ActiveSupport::TestCase
  test "renders safe inline svg with four independently clipped parts" do
    impression = sample_impression(description: "<script>alert('no')</script>")
    svg = ObservationVisualRenderer.new(impression, id_prefix: "sample-one", label: "Duck <sample>").render.to_s
    document = Nokogiri::XML(svg)

    assert_empty document.errors
    assert_equal 1, document.xpath("//*[local-name()='svg']").count
    assert_equal 4, document.xpath("//*[@data-impression-part]").count
    assert_equal 4, document.xpath("//*[local-name()='clipPath']").count
    assert_empty document.xpath("//*[local-name()='script' or local-name()='foreignObject' or local-name()='image']")
    assert_empty document.xpath("//@href | //@*[local-name()='href']")
    assert_not_includes svg, "alert('no')"
    assert_includes svg, "sample-one-clip-head"
    assert_includes svg, "sample-one-pattern-streaked"
    assert_includes svg, %(clip-path="url(#sample-one-clip-chest_belly)")
    assert_not_includes svg, "clip_path="
  end

  test "keeps definition ids isolated between inline birds" do
    impression = sample_impression
    first = Nokogiri::XML(ObservationVisualRenderer.new(impression, id_prefix: "bird-one", label: "one").render.to_s)
    second = Nokogiri::XML(ObservationVisualRenderer.new(impression, id_prefix: "bird-two", label: "two").render.to_s)

    first_ids = first.xpath("//@id").map(&:value)
    second_ids = second.xpath("//@id").map(&:value)

    assert_empty first_ids & second_ids
    assert first_ids.all? { |id| id.start_with?("bird-one-") }
    assert second_ids.all? { |id| id.start_with?("bird-two-") }
  end

  test "uses a structural replacement for long tail" do
    impression = sample_impression(tail_feature: "long_tail")
    svg = ObservationVisualRenderer.new(impression, id_prefix: "long-tail", label: "long tail").render.to_s

    assert_includes svg, "M116 134 C84 141 49 159 18 190"
    assert_not_includes svg, "M113 135 C88 140 62 153"
  end

  test "refuses an unmapped or invalid outline" do
    impression = ObservationImpression.new(outline_key: "generic", parts: {})

    assert_raises(KeyError) do
      ObservationVisualRenderer.new(impression, id_prefix: "generic", label: "generic").render
    end
  end

  private

  def sample_impression(description: nil, tail_feature: "barred")
    ObservationImpression.new(
      outline_key: "compact_passerine",
      parts: {
        head: { primary_color_key: "black", secondary_color_key: "white", feature_key: "cheek_patch", certainty_key: "certain" },
        chest_belly: { primary_color_key: "yellow", feature_key: "streaked", description:, certainty_key: "probable" },
        wing: { primary_color_key: "blue", secondary_color_key: "white", feature_key: "wing_bars", certainty_key: "certain" },
        tail: { primary_color_key: "blue_gray", feature_key: tail_feature, certainty_key: "vague" }
      }
    )
  end
end
