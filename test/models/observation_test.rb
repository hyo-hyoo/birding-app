require "test_helper"
require_relative "../support/observation_test_support"

class ObservationTest < ActiveSupport::TestCase
  include ObservationTestSupport

  test "observation accepts only configured outline and normalizes optional behavior" do
    observation = Observation.new(user: create_observer, outline_key: " generic ", behavior_text: "  perched  ")
    assert observation.valid?
    assert_equal "generic", observation.outline_key
    assert_equal "perched", observation.behavior_text

    observation.outline_key = "unknown"
    assert_not observation.valid?
    assert observation.errors[:outline_key].any?
    observation.outline_key = "generic"
    observation.behavior_text = "a" * 2001
    assert_not observation.valid?
    assert observation.errors[:behavior_text].any?
  end

  test "part impression validates content configuration certainty and color dependency" do
    observation = Observation.create!(user: create_observer, outline_key: "generic")
    impression = observation.part_impressions.build(
      part_key: " head ", primary_color_key: " black ", secondary_color_key: " white ",
      feature_key: " eye_ring ", description: "  pale eyebrow  ", certainty_key: " certain "
    )
    assert impression.valid?
    assert_equal "head", impression.part_key
    assert_equal "pale eyebrow", impression.description

    impression.feature_key = "wing_bars"
    assert_not impression.valid?
    assert impression.errors[:feature_key].any?
    impression.feature_key = nil
    impression.secondary_color_key = "black"
    assert_not impression.valid?
    assert impression.errors[:secondary_color_key].any?
    impression.primary_color_key = nil
    impression.secondary_color_key = nil
    impression.description = nil
    assert_not impression.valid?
    assert impression.errors[:base].any?
  end

  test "activity location validates configured unique key and one of two slots" do
    observation = Observation.create!(user: create_observer, outline_key: "generic")
    first = observation.activity_location_selections.create!(location_key: " water_surface ", slot: 1)
    assert_equal "water_surface", first.location_key

    assert_not observation.activity_location_selections.build(location_key: "water_surface", slot: 2).valid?
    assert_not observation.activity_location_selections.build(location_key: "unknown", slot: 2).valid?
    assert_not observation.activity_location_selections.build(location_key: "air", slot: 3).valid?
  end

  test "owner and first save time are immutable through models" do
    first_user = create_observer
    second_user = create_observer
    observation = Observation.create!(user: first_user, outline_key: "generic")
    original_created_at = observation.created_at

    assert_raises(ActiveRecord::ReadonlyAttributeError) { observation.update!(user: second_user) }
    assert_raises(ActiveRecord::ReadonlyAttributeError) { observation.update!(created_at: 1.day.ago) }
    assert_equal original_created_at, observation.reload.created_at
    assert_equal first_user, observation.user
  end
end
