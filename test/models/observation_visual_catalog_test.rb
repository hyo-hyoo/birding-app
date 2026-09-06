require "test_helper"

class ObservationVisualCatalogTest < ActiveSupport::TestCase
  test "loads and freezes the three stage 8A mappings" do
    assert_equal %w[anatidae ardeidae compact_passerine], ObservationVisualCatalog.outline_keys
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
      end
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

  test "loads trusted source geometry for all three sample silhouettes" do
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
  end
end
