class ObservationSubmission
  include ActiveModel::Model

  attr_accessor :outline_key, :behavior_text, :parts, :activity_location_keys, :expected_revision
  attr_reader :observation, :normalized_parts, :normalized_activity_location_keys

  validate :validate_submission

  def self.from_observation(observation)
    new(
      outline_key: observation.outline_key,
      behavior_text: observation.behavior_text,
      expected_revision: observation.content_revision,
      parts: observation.part_impressions.each_with_object({}) do |impression, values|
        values[impression.part_key] = impression.attributes.slice(
          "primary_color_key", "secondary_color_key", "feature_key", "description", "certainty_key"
        )
      end,
      activity_location_keys: observation.activity_location_selections.sort_by(&:slot).map(&:location_key)
    )
  end

  def create(user:)
    return false unless valid?(:create)

    Observation.transaction do
      @observation = user.observations.create!(
        outline_key: normalized_outline_key,
        behavior_text: normalized_behavior_text
      )
      persist_children!
    end
    true
  end

  def update(user:, observation_id:)
    return false unless valid?(:update)

    saved = false
    Observation.transaction do
      @observation = user.observations.lock.find(observation_id)
      unless @observation.content_revision == normalized_expected_revision
        errors.add(:expected_revision, :stale)
        raise ActiveRecord::Rollback
      end

      @observation.update!(
        outline_key: normalized_outline_key,
        behavior_text: normalized_behavior_text,
        content_revision: @observation.content_revision + 1
      )
      persist_children!
      saved = true
    end
    saved
  end

  private

  def validate_submission
    normalize_submission
    validate_outline
    validate_behavior
    validate_parts
    validate_locations
    validate_expected_revision if validation_context == :update
  end

  def normalize_submission
    @normalized_outline_key = scalar_value(outline_key)&.strip.to_s
    @normalized_behavior_text = scalar_value(behavior_text)&.strip.presence
    @normalized_parts = normalize_parts
    @normalized_activity_location_keys = normalize_locations
    @normalized_expected_revision = Integer(expected_revision, exception: false)
  end

  attr_reader :normalized_outline_key, :normalized_behavior_text, :normalized_expected_revision

  def normalize_parts
    source = hash_value(parts)
    return {} unless source

    source.each_with_object({}) do |(raw_part_key, raw_attributes), result|
      part_key = scalar_value(raw_part_key)&.strip.to_s
      attributes = hash_value(raw_attributes)
      unless attributes
        errors.add(:parts, :invalid)
        next
      end

      values = attributes.with_indifferent_access
      normalized = {
        part_key: part_key,
        primary_color_key: scalar_value(values[:primary_color_key])&.strip.presence,
        secondary_color_key: scalar_value(values[:secondary_color_key])&.strip.presence,
        feature_key: scalar_value(values[:feature_key])&.strip.presence,
        description: scalar_value(values[:description])&.strip.presence,
        certainty_key: scalar_value(values[:certainty_key])&.strip.presence
      }
      normalized[:secondary_color_key] = nil if normalized[:primary_color_key].blank?
      result[part_key] = normalized if visual_content?(normalized)
    end
  end

  def normalize_locations
    values = activity_location_keys
    values = values.values if values.respond_to?(:values) && !values.is_a?(Array)
    Array(values).filter_map { |value| scalar_value(value)&.strip.presence }
  end

  def validate_outline
    errors.add(:outline_key, :inclusion) unless ObservationOptions.valid_outline_key?(normalized_outline_key)
  end

  def validate_behavior
    errors.add(:behavior_text, :too_long, count: 2000) if normalized_behavior_text&.length.to_i > 2000
  end

  def validate_parts
    source = hash_value(parts)
    errors.add(:parts, :invalid) if parts.present? && source.nil?
    source&.each_key do |raw_key|
      key = scalar_value(raw_key)&.strip.to_s
      errors.add(:parts, :inclusion) unless ObservationOptions.valid_part_key?(key)
    end

    errors.add(:parts, :blank) if normalized_parts.empty?
    normalized_parts.each_value do |attributes|
      impression = PartImpression.new(attributes.merge(observation: Observation.new))
      next if impression.valid?

      impression.errors.each { |error| errors.add(:parts, error.type, **error.options) }
    end
  end

  def validate_locations
    if normalized_activity_location_keys.length > 2
      errors.add(:activity_location_keys, :too_long, count: 2)
    end
    if normalized_activity_location_keys.uniq.length != normalized_activity_location_keys.length
      errors.add(:activity_location_keys, :taken)
    end
    normalized_activity_location_keys.each do |key|
      errors.add(:activity_location_keys, :inclusion) unless ObservationOptions.valid_activity_location_key?(key)
    end
  end

  def validate_expected_revision
    errors.add(:expected_revision, :invalid) if normalized_expected_revision.nil? || normalized_expected_revision.negative?
  end

  def persist_children!
    existing_parts = observation.part_impressions.index_by(&:part_key)
    (existing_parts.keys - normalized_parts.keys).each { |part_key| existing_parts.fetch(part_key).destroy! }
    normalized_parts.each do |part_key, attributes|
      impression = existing_parts[part_key] || observation.part_impressions.build(part_key: part_key)
      impression.assign_attributes(attributes.except(:part_key))
      impression.save!
    end

    ActivityLocationSelection.where(observation_id: observation.id).delete_all
    normalized_activity_location_keys.each_with_index do |location_key, index|
      observation.activity_location_selections.create!(location_key: location_key, slot: index + 1)
    end
  end

  def visual_content?(attributes)
    attributes.values_at(:primary_color_key, :feature_key, :description).any?(&:present?)
  end

  def hash_value(value)
    return value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
    return value.to_h if value.respond_to?(:to_h)

    nil
  end

  def scalar_value(value)
    value.to_s if value.is_a?(String) || value.is_a?(Symbol) || value.is_a?(Numeric)
  end
end
