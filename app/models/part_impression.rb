class PartImpression < ApplicationRecord
  belongs_to :observation, inverse_of: :part_impressions

  attr_readonly :observation_id, :part_key

  normalizes :part_key, :primary_color_key, :secondary_color_key, :feature_key, :certainty_key,
    with: ->(value) { value.to_s.strip.presence }
  normalizes :description, with: ->(value) { value.to_s.strip.presence }

  validates :part_key, presence: true, inclusion: { in: ->(_) { ObservationOptions.part_keys } },
    uniqueness: { scope: :observation_id }
  validates :certainty_key, presence: true, inclusion: { in: ->(_) { ObservationOptions.certainty_keys } }
  validates :description, length: { maximum: 2000 }, allow_nil: true
  validate :configured_colors
  validate :feature_applies_to_part
  validate :has_visual_content
  validate :secondary_color_depends_on_primary

  def visual_content?
    primary_color_key.present? || feature_key.present? || description.present?
  end

  private

  def configured_colors
    [ :primary_color_key, :secondary_color_key ].each do |attribute|
      key = public_send(attribute)
      errors.add(attribute, :inclusion) if key.present? && !ObservationOptions.valid_color_key?(key)
    end
  end

  def feature_applies_to_part
    return if feature_key.blank? || part_key.blank?

    errors.add(:feature_key, :inclusion) unless ObservationOptions.valid_feature_for_part?(feature_key, part_key)
  end

  def has_visual_content
    errors.add(:base, :blank) unless visual_content?
  end

  def secondary_color_depends_on_primary
    return if secondary_color_key.blank?

    errors.add(:secondary_color_key, :invalid) if primary_color_key.blank? || secondary_color_key == primary_color_key
  end
end
