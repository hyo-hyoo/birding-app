require "test_helper"

class ObservationVisualCatalogTest < ActiveSupport::TestCase
  test "loads freezes and completely maps every configured outline" do
    assert_equal ObservationOptions.outline_keys.sort, ObservationVisualCatalog.outline_keys.sort
    assert_equal 17, ObservationVisualCatalog.outline_keys.size
    assert_predicate ObservationVisualCatalog.config, :frozen?

    ObservationVisualCatalog.outlines.each do |outline_key, outline|
      assert_equal ObservationOptions.part_keys.sort, outline.fetch(:parts).keys.map(&:to_s).sort
      assert_equal(
        ObservationOptions.outlines.find { |entry| entry.fetch(:key) == outline_key.to_s }.fetch(:asset),
        outline.fetch(:source_asset)
      )

      outline.fetch(:parts).each_value do |part|
        assert_not_empty part.fetch(:base)
        assert_not_empty part.fetch(:secondary)
        assert_equal %i[angle height width x y], part.fetch(:feature_anchor).keys.sort
      end
      assert outline.fetch(:parts).values.none? { |part| part.key?(:variants) }
    end
  end

  test "uses only local trusted vector primitives" do
    serialized = ObservationVisualCatalog.config.to_json

    assert_no_match(/<script|foreignObject|javascript:/i, serialized)
    assert_no_match(/https?:\/\//i, serialized)

    ObservationVisualCatalog.outlines.each_value do |outline|
      assert_match(/\Aobservation_outlines\/[a-z_]+\.svg\z/, outline.fetch(:source_asset))
    end
  end

  test "maps configured colors without accepting arbitrary values" do
    assert_equal "#F5F3EA", ObservationVisualCatalog.color_hex("white")
    assert_nil ObservationVisualCatalog.color_hex("url(https://example.test/paint)")
  end

  test "loads trusted source geometry for every silhouette" do
    duck = ObservationVisualCatalog.source_geometry("anatidae")
    heron = ObservationVisualCatalog.source_geometry("ardeidae")
    compact = ObservationVisualCatalog.source_geometry("compact_passerine")

    assert_equal [ 0.0, 0.0, 1536.0, 653.0 ], duck.fetch(:view_box)
    assert_equal [ 0.0, 0.0, 699.0, 1536.0 ], heron.fetch(:view_box)
    assert_equal "translate(0.000000,653.000000) scale(0.100000,-0.100000)", duck.fetch(:transform)
    assert_equal "translate(0.000000,1536.000000) scale(0.100000,-0.100000)", heron.fetch(:transform)
    assert_equal [ 0.0, 0.0, 1536.0, 1206.0 ], compact.fetch(:view_box)
    assert_equal "translate(0.000000,1206.000000) scale(0.100000,-0.100000)", compact.fetch(:transform)
    assert_equal 1, duck.fetch(:paths).length
    assert_equal 1, heron.fetch(:paths).length
    assert_equal 1, compact.fetch(:paths).length

    ObservationVisualCatalog.outline_keys.each do |outline_key|
      geometry = ObservationVisualCatalog.source_geometry(outline_key)

      assert_equal 4, geometry.fetch(:view_box).length
      assert geometry.fetch(:view_box).drop(2).all?(&:positive?)
      assert_match(/\Atranslate\(.+\) scale\(.+\)\z/, geometry.fetch(:transform))
      assert_not_empty geometry.fetch(:paths)
    end
  end


  test "classifies only color-block features as visual" do
    assert ObservationVisualCatalog.visual_feature?("wing", "wing_patch")
    assert ObservationVisualCatalog.visual_feature?("head", "eye_ring")
    assert_not ObservationVisualCatalog.visual_feature?("wing", "streaked")
    assert_not ObservationVisualCatalog.visual_feature?("wing", "pale_feather_edges")
    assert_not ObservationVisualCatalog.visual_feature?("head", "crest")
    assert_not ObservationVisualCatalog.visual_feature?("tail", "forked_tail")
    assert_not ObservationVisualCatalog.visual_feature?("tail", "long_tail")
  end
end
