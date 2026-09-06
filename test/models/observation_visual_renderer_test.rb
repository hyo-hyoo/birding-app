require "test_helper"

class ObservationVisualRendererTest < ActiveSupport::TestCase
  test "renders safe inline svg with four independently clipped parts" do
    impression = sample_impression(description: "<script>alert('no')</script>")
    svg = ObservationVisualRenderer.new(impression, id_prefix: "sample-one", label: "Duck <sample>").render.to_s
    document = Nokogiri::XML(svg)

    assert_empty document.errors
    assert_equal 1, document.xpath("//*[local-name()='svg']").count
    assert_equal 4, document.xpath("//*[@data-impression-part]").count
    assert_equal 5, document.xpath("//*[local-name()='clipPath']").count
    assert_empty document.xpath("//*[local-name()='script' or local-name()='foreignObject' or local-name()='image']")
    assert_empty document.xpath("//@href | //@*[local-name()='href']")
    assert_not_includes svg, "alert('no')"
    assert_includes svg, "sample-one-clip-head"
    assert_not_includes svg, "sample-one-pattern-streaked"
    assert_empty document.xpath("//*[local-name()='pattern' or local-name()='linearGradient']")
    assert_equal 5, document.xpath("//*[local-name()='clipPath']").count
    assert_not_includes svg, "clip_path="
    assert_not_includes svg, "stroke_width="
  end

  test "clips source-based samples to their registered PhyloPic silhouette" do
    impression = ObservationImpression.new(
      outline_key: "anatidae",
      parts: { chest_belly: { primary_color_key: "white", certainty_key: "certain" } }
    )
    svg = ObservationVisualRenderer.new(impression, id_prefix: "source-duck", label: "water duck").render.to_s
    document = Nokogiri::XML(svg)

    assert_empty document.errors
    assert_equal 1, document.xpath("//*[@id='source-duck-clip-silhouette']").count
    assert_includes svg, %(clip-path="url(#source-duck-clip-silhouette)")
    assert_includes svg, "translate(0.000000,653.000000) scale(0.100000,-0.100000)"
    assert_no_match(/(?:href|src)=["']https?:/i, svg)
    assert_no_match(/url\(["']?https?:/i, svg)
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

  test "keeps the source-backed long-tail silhouette and a single wing secondary region" do
    impression = sample_impression(tail_feature: "long_tail")
    svg = ObservationVisualRenderer.new(impression, id_prefix: "long-tail", label: "long tail").render.to_s
    document = Nokogiri::XML(svg)

    assert_includes svg, "translate(0.000000,1206.000000) scale(0.100000,-0.100000)"
    assert_equal 1, document.xpath("//*[@data-impression-part='wing']//*[contains(@class, 'observation-impression__secondary')]").count
    assert_empty document.xpath("//*[@data-impression-part='wing']//*[@data-feature-key]")
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
