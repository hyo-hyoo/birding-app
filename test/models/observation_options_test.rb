require "test_helper"

class ObservationOptionsTest < ActiveSupport::TestCase
  EXPECTED_COUNTS = {
    outline_groups: 4,
    orders: 12,
    outlines: 17,
    colors: 12,
    parts: 4,
    features: 23,
    certainties: 3,
    activity_locations: 11
  }.freeze

  test "configuration has the confirmed option counts and unique stable keys" do
    EXPECTED_COUNTS.each do |section, count|
      entries = ObservationOptions.public_send(section)
      keys = entries.map { |entry| entry.fetch(:key) }

      assert_equal count, entries.size, section
      assert_equal keys.uniq, keys, section
      assert keys.all? { |key| key.match?(/\A[a-z][a-z0-9_]*\z/) }, section
    end
  end

  test "outlines reference valid groups orders local svg assets and complete cc0 sources" do
    group_keys = ObservationOptions.outline_groups.pluck(:key)
    order_keys = ObservationOptions.orders.pluck(:key)
    fallbacks = ObservationOptions.outlines.select { |outline| outline[:fallback] }

    assert_equal [ "generic" ], fallbacks.pluck(:key)

    ObservationOptions.outlines.each do |outline|
      unless outline[:fallback]
        assert_includes group_keys, outline.fetch(:group_key)
        assert_includes order_keys, outline.fetch(:order_key)
        assert_not_empty outline.fetch(:family_keys)
      end

      asset = Rails.root.join("app/assets/images", outline.fetch(:asset))
      assert_path_exists asset
      svg = asset.read
      assert_includes svg, "<svg"
      assert_no_match(/<script|javascript:|<foreignObject|<image\b|\b(?:xlink:)?href=/i, svg)

      source = outline.fetch(:source)
      assert_equal "PhyloPic", source.fetch(:provider)
      assert_equal "CC0-1.0", source.fetch(:license)
      assert_match(/\A[0-9a-f-]{36}\z/, source.fetch(:image_uuid))
      assert_match(%r{\Ahttps://www\.phylopic\.org/images/}, source.fetch(:page_url))
      assert_match(%r{\Ahttps://images\.phylopic\.org/images/.+/vector\.svg\z}, source.fetch(:vector_url))
      assert_not_empty source.fetch(:representative_taxon)
      assert_not_empty source.fetch(:creator)
    end
  end

  test "colors use unique uppercase hex values" do
    hex_values = ObservationOptions.colors.pluck(:hex)

    assert_equal hex_values.uniq, hex_values
    assert hex_values.all? { |hex| hex.match?(/\A#[0-9A-F]{6}\z/) }
  end

  test "features are limited to configured parts and expose the confirmed applicability" do
    part_keys = ObservationOptions.part_keys

    ObservationOptions.features.each do |feature|
      assert_not_empty feature.fetch(:parts)
      assert_empty feature.fetch(:parts) - part_keys
    end

    assert ObservationOptions.valid_feature_for_part?(:eye_ring, :head)
    assert_not ObservationOptions.valid_feature_for_part?(:eye_ring, :wing)
    assert ObservationOptions.valid_feature_for_part?(:barred, :tail)
    assert ObservationOptions.valid_feature_for_part?(:speculum, :wing)
  end

  test "all user visible configuration entries have Chinese and Japanese translations" do
    sections = {
      outline_groups: ObservationOptions.outline_groups,
      orders: ObservationOptions.orders,
      outlines: ObservationOptions.outlines,
      colors: ObservationOptions.colors,
      parts: ObservationOptions.parts,
      features: ObservationOptions.features,
      certainties: ObservationOptions.certainties,
      activity_locations: ObservationOptions.activity_locations
    }

    %i[zh-CN ja].each do |locale|
      sections.each do |section, entries|
        entries.each do |entry|
          label = ObservationOptions.label(section, entry.fetch(:key), locale:)
          assert_not_empty label
          refute_match(/translation missing/i, label)
        end
      end
    end
  end

  test "public key predicates use strings consistently and configuration is immutable" do
    assert ObservationOptions.valid_outline_key?(:anatidae)
    assert ObservationOptions.valid_color_key?(:blue_gray)
    assert ObservationOptions.valid_part_key?(:chest_belly)
    assert ObservationOptions.valid_certainty_key?(:probable)
    assert ObservationOptions.valid_activity_location_key?(:tree_branch)
    assert_not ObservationOptions.valid_outline_key?(:unknown)

    assert_raises(FrozenError) { ObservationOptions.colors.first[:hex] = "#FFFFFF" }
  end
end
