class ObservationImpression
  PART_ORDER = ObservationOptions.part_keys.freeze

  Part = Data.define(
    :key,
    :primary_color_key,
    :secondary_color_key,
    :feature_key,
    :description,
    :certainty_key
  ) do
    def recorded?
      primary_color_key.present? || feature_key.present? || description.present?
    end
  end

  attr_reader :outline_key, :parts

  def initialize(outline_key:, parts:)
    @outline_key = normalize_outline(outline_key)
    @parts = normalize_parts(parts).freeze
    freeze
  end

  def mapped?
    ObservationVisualCatalog.mapped?(outline_key)
  end

  def part(part_key)
    parts.fetch(part_key.to_s)
  end

  def recorded_parts
    PART_ORDER.filter_map do |part_key|
      candidate = parts.fetch(part_key)
      candidate if candidate.recorded?
    end
  end

  private

  def normalize_outline(value)
    key = value.to_s.strip
    ObservationOptions.valid_outline_key?(key) ? key.freeze : nil
  end

  def normalize_parts(input)
    submitted = if input.respond_to?(:to_unsafe_h)
      input.to_unsafe_h
    elsif input.respond_to?(:to_h)
      input.to_h
    else
      {}
    end

    keyed = submitted.each_with_object({}) do |(key, value), result|
      result[key.to_s] = value.respond_to?(:to_h) ? value.to_h.stringify_keys : {}
    end

    PART_ORDER.index_with do |part_key|
      normalize_part(part_key, keyed.fetch(part_key, {}))
    end
  end

  def normalize_part(part_key, values)
    primary = valid_color(values["primary_color_key"])
    secondary = valid_color(values["secondary_color_key"])
    secondary = nil if primary.nil? || secondary == primary

    feature = values["feature_key"].to_s.strip.presence
    feature = nil unless feature && ObservationOptions.valid_feature_for_part?(feature, part_key)

    certainty = values["certainty_key"].to_s.strip.presence
    certainty = nil unless certainty && ObservationOptions.valid_certainty_key?(certainty)

    Part.new(
      key: part_key.freeze,
      primary_color_key: primary,
      secondary_color_key: secondary,
      feature_key: feature&.freeze,
      description: values["description"].to_s.strip.presence&.freeze,
      certainty_key: certainty&.freeze
    ).freeze
  end

  def valid_color(value)
    key = value.to_s.strip.presence
    key&.freeze if key && ObservationOptions.valid_color_key?(key)
  end
end
