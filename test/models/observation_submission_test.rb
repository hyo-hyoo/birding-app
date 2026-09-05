require "test_helper"
require_relative "../support/observation_test_support"

class ObservationSubmissionTest < ActiveSupport::TestCase
  include ObservationTestSupport

  test "create saves one normalized aggregate and omits empty parts" do
    user = create_observer
    submission = ObservationSubmission.new(valid_observation_attributes)

    assert_difference({ "Observation.count" => 1, "PartImpression.count" => 1, "ActivityLocationSelection.count" => 2 }) do
      assert submission.create(user: user)
    end

    observation = submission.observation.reload
    assert_equal user, observation.user
    assert_equal "anatidae", observation.outline_key
    assert_equal "slowly swimming", observation.behavior_text
    assert_equal 0, observation.content_revision
    assert_equal %w[head], observation.part_impressions.pluck(:part_key)
    assert_equal "bright cheek", observation.part_impressions.first.description
    assert_equal %w[water_surface shallow_water], observation.activity_location_selections.order(:slot).pluck(:location_key)
  end

  test "minimum save condition and invalid configuration leave no partial rows" do
    user = create_observer
    attributes = valid_observation_attributes.deep_dup
    attributes[:parts] = { head: { certainty_key: "certain", description: "  " } }
    submission = ObservationSubmission.new(attributes)

    assert_no_difference [ "Observation.count", "PartImpression.count", "ActivityLocationSelection.count" ] do
      assert_not submission.create(user: user)
    end
    assert submission.errors[:parts].any?

    attributes[:parts] = { head: { feature_key: "wing_bars", certainty_key: "certain" } }
    submission = ObservationSubmission.new(attributes)
    assert_not submission.create(user: user)
    assert submission.errors[:parts].any?
  end

  test "create rolls back the parent and all children when a late write fails" do
    user = create_observer
    submission = ObservationSubmission.new(valid_observation_attributes)
    failure = -> { raise "injected activity failure" }
    ActivityLocationSelection.set_callback(:create, :before, failure)

    assert_no_difference [ "Observation.count", "PartImpression.count", "ActivityLocationSelection.count" ] do
      assert_raises(RuntimeError) { submission.create(user: user) }
    end
  ensure
    ActivityLocationSelection.skip_callback(:create, :before, failure) if failure
  end

  test "update replaces full child collections removes emptied parts and increments revision" do
    user = create_observer
    original = ObservationSubmission.new(valid_observation_attributes)
    assert original.create(user: user)
    observation = original.observation
    created_at = observation.created_at

    attributes = valid_observation_attributes.deep_dup
    attributes[:expected_revision] = 0
    attributes[:behavior_text] = " flying away "
    attributes[:parts] = {
      head: { certainty_key: "certain" },
      tail: { feature_key: "forked_tail", certainty_key: "probable" }
    }
    attributes[:activity_location_keys] = [ "air" ]
    update = ObservationSubmission.new(attributes)

    assert update.update(user: user, observation_id: observation.id)
    observation.reload
    assert_equal 1, observation.content_revision
    assert_equal created_at, observation.created_at
    assert_equal "flying away", observation.behavior_text
    assert_equal %w[tail], observation.part_impressions.pluck(:part_key)
    assert_equal [ [ "air", 1 ] ], observation.activity_location_selections.pluck(:location_key, :slot)
  end

  test "missing or stale revision rejects the whole update and preserves submitted values" do
    user = create_observer
    original = ObservationSubmission.new(valid_observation_attributes)
    assert original.create(user: user)
    observation = original.observation

    [ nil, "bad", 1 ].each do |expected_revision|
      attributes = valid_observation_attributes.deep_dup.merge(
        expected_revision: expected_revision,
        outline_key: "generic",
        behavior_text: "new behavior"
      )
      submission = ObservationSubmission.new(attributes)
      assert_not submission.update(user: user, observation_id: observation.id)
      assert submission.errors[:expected_revision].any?
      assert_equal "new behavior", submission.behavior_text
      assert_equal "anatidae", observation.reload.outline_key
      assert_equal 0, observation.content_revision
    end
  end

  test "duplicate or excessive locations and cross-user ids are rejected" do
    user = create_observer
    other_user = create_observer
    original = ObservationSubmission.new(valid_observation_attributes)
    assert original.create(user: user)

    [ %w[air air], %w[air shrub ground], %w[air unknown] ].each do |locations|
      submission = ObservationSubmission.new(valid_observation_attributes.merge(activity_location_keys: locations))
      assert_not submission.create(user: user)
      assert submission.errors[:activity_location_keys].any?
    end

    update = ObservationSubmission.new(valid_observation_attributes.merge(expected_revision: 0))
    assert_raises(ActiveRecord::RecordNotFound) do
      update.update(user: other_user, observation_id: original.observation.id)
    end
  end
end
