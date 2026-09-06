class ObservationSummary
  Item = Data.define(:part_key, :part_label, :details, :certainty_label)

  attr_reader :impression, :locale

  def initialize(impression, locale: I18n.locale)
    @impression = impression
    @locale = locale
  end

  def items
    impression.recorded_parts.map do |part|
      Item.new(
        part_key: part.key,
        part_label: option_label(:parts, part.key),
        details: details_for(part).freeze,
        certainty_label: certainty_label(part)
      ).freeze
    end.freeze
  end

  def empty?
    items.empty?
  end

  private

  def details_for(part)
    details = []
    details << translate(:primary, value: option_label(:colors, part.primary_color_key)) if part.primary_color_key
    details << translate(:secondary, value: option_label(:colors, part.secondary_color_key)) if part.secondary_color_key
    details << translate(:feature, value: option_label(:features, part.feature_key)) if part.feature_key
    details << translate(:description, value: part.description) if part.description
    details
  end

  def certainty_label(part)
    return option_label(:certainties, part.certainty_key) if part.certainty_key

    translate(:certainty_pending)
  end

  def translate(key, **options)
    I18n.t!("observation_impressions.summary.#{key}", locale:, **options)
  end

  def option_label(section, key)
    ObservationOptions.label(section, key, locale:)
  end
end
