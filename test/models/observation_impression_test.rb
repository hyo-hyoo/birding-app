require "test_helper"

class ObservationImpressionTest < ActiveSupport::TestCase
  test "normalizes safe preview data and keeps recorded parts in canonical order" do
    impression = ObservationImpression.new(
      outline_key: " anatidae ",
      parts: {
        tail: { description: " tail note ", certainty_key: "probable" },
        head: { primary_color_key: "green", feature_key: "eye_ring", certainty_key: "certain" }
      }
    )

    assert_equal "anatidae", impression.outline_key
    assert_equal %w[head tail], impression.recorded_parts.map(&:key)
    assert_equal "tail note", impression.part("tail").description
    assert_predicate impression, :frozen?
  end

  test "filters invalid keys and invalid secondary color combinations" do
    impression = ObservationImpression.new(
      outline_key: "unknown",
      parts: {
        head: {
          primary_color_key: "javascript:alert(1)",
          secondary_color_key: "red",
          feature_key: "forked_tail",
          certainty_key: "invented",
          description: "kept as text"
        }
      }
    )

    assert_nil impression.outline_key
    assert_not_predicate impression, :mapped?
    assert_nil impression.part("head").primary_color_key
    assert_nil impression.part("head").secondary_color_key
    assert_nil impression.part("head").feature_key
    assert_nil impression.part("head").certainty_key
    assert_equal "kept as text", impression.part("head").description
  end

  test "keeps a description-only part for an incomplete preview" do
    impression = ObservationImpression.new(outline_key: "ardeidae", parts: { wing: { description: "only text" } })

    assert_equal %w[wing], impression.recorded_parts.map(&:key)
    assert_nil impression.part("wing").primary_color_key
  end

  test "derives the same read-only shape from a saved observation and a form submission" do
    observation = Observation.new(outline_key: "corvidae")
    observation.part_impressions.build(
      part_key: "tail", primary_color_key: "black", feature_key: "forked_tail",
      description: "clearly split", certainty_key: "certain"
    )
    submission = ObservationSubmission.from_observation(observation)

    saved_impression = ObservationImpression.from_observation(observation)
    form_impression = ObservationImpression.from_submission(submission)

    assert_equal saved_impression.outline_key, form_impression.outline_key
    assert_equal saved_impression.parts, form_impression.parts
    assert_equal "forked_tail", saved_impression.part("tail").feature_key
  end
end
