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

  test "keeps structural features in text only without changing the source silhouette" do
    [
      [ "head", "crest" ],
      [ "tail", "forked_tail" ],
      [ "tail", "long_tail" ]
    ].each_with_index do |(part_key, feature_key), index|
      plain = impression_with_feature(part_key, nil)
      described = impression_with_feature(part_key, feature_key)
      prefix = "summary-only-#{index}"
      plain_svg = ObservationVisualRenderer.new(plain, id_prefix: prefix, label: "bird").render.to_s
      described_svg = ObservationVisualRenderer.new(described, id_prefix: prefix, label: "bird").render.to_s

      assert_equal plain_svg, described_svg
      assert_not_includes described_svg, feature_key
    end
  end

  test "maps all outlines and keeps each svg self-contained" do
    ObservationOptions.outline_keys.each_with_index do |outline_key, index|
      impression = sample_impression(outline_key:)
      svg = ObservationVisualRenderer.new(impression, id_prefix: "outline-#{index}", label: outline_key).render.to_s
      document = Nokogiri::XML(svg)

      assert_empty document.errors
      assert_equal 4, document.xpath("//*[@data-impression-part]").count
      assert_equal 5, document.xpath("//*[local-name()='clipPath']").count
      assert_empty document.xpath("//*[local-name()='script' or local-name()='foreignObject' or local-name()='image']")
      assert_no_match(/(?:href|src)=[\"']https?:/i, svg)
    end
  end

  test "renders all colors and valid features without accepting markup" do
    ObservationOptions.colors.each_with_index do |color, index|
      svg = ObservationVisualRenderer.new(
        sample_impression(wing_color: color.fetch(:key)),
        id_prefix: "color-#{index}",
        label: color.fetch(:key)
      ).render.to_s

      assert_includes svg, ObservationVisualCatalog.color_hex(color.fetch(:key))
      assert_no_match(/<script|foreignObject|javascript:/i, svg)
    end

    ObservationOptions.features.each_with_index do |feature, index|
      part_key = feature.fetch(:parts).first
      impression = impression_with_feature(part_key, feature.fetch(:key))
      svg = ObservationVisualRenderer.new(impression, id_prefix: "feature-#{index}", label: feature.fetch(:key)).render.to_s

      document = Nokogiri::XML(svg)
      assert_empty document.xpath("//*[local-name()='script' or local-name()='foreignObject' or local-name()='image']")
      assert_empty document.xpath("//@href | //@src | //@*[local-name()='href']")
      assert_no_match(/javascript:/i, svg)
    end
  end

  test "keeps fine features in text only and does not infer a color block" do
    plain = impression_with_feature("chest_belly", nil)
    streaked = impression_with_feature("chest_belly", "streaked")
    plain_svg = ObservationVisualRenderer.new(plain, id_prefix: "text-only", label: "bird").render.to_s
    streaked_svg = ObservationVisualRenderer.new(streaked, id_prefix: "text-only", label: "bird").render.to_s

    assert_equal plain_svg, streaked_svg
    assert_not_includes streaked_svg, "streaked"
    assert_empty Nokogiri::XML(streaked_svg).xpath("//*[@data-secondary-for='chest_belly']")
  end

  test "refuses an invalid outline" do
    impression = ObservationImpression.new(outline_key: "not-an-outline", parts: {})

    assert_raises(KeyError) do
      ObservationVisualRenderer.new(impression, id_prefix: "generic", label: "generic").render
    end
  end

  private

  def sample_impression(description: nil, tail_feature: "barred", outline_key: "compact_passerine", wing_color: "white")
    ObservationImpression.new(
      outline_key:,
      parts: {
        head: { primary_color_key: "black", secondary_color_key: "white", feature_key: "cheek_patch", certainty_key: "certain" },
        chest_belly: { primary_color_key: "yellow", feature_key: "streaked", description:, certainty_key: "probable" },
        wing: { primary_color_key: "blue", secondary_color_key: wing_color, feature_key: "wing_bars", certainty_key: "certain" },
        tail: { primary_color_key: "blue_gray", feature_key: tail_feature, certainty_key: "vague" }
      }
    )
  end

  def impression_with_feature(part_key, feature_key)
    ObservationImpression.new(
      outline_key: "compact_passerine",
      parts: {
        part_key => {
          primary_color_key: "brown",
          feature_key:,
          certainty_key: "certain"
        }
      }
    )
  end
end
