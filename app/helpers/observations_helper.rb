module ObservationsHelper
  def submission_part_values(submission, part_key)
    source = if submission.parts.respond_to?(:to_unsafe_h)
      submission.parts.to_unsafe_h
    elsif submission.parts.respond_to?(:to_h)
      submission.parts.to_h
    else
      {}
    end
    source.with_indifferent_access.fetch(part_key.to_s, {}).with_indifferent_access
  end

  def submission_location_keys(submission)
    values = submission.activity_location_keys
    values = values.values if values.respond_to?(:values) && !values.is_a?(Array)
    Array(values).map(&:to_s)
  end

  def observation_option_label(section, key)
    ObservationOptions.label(section, key)
  end
end
