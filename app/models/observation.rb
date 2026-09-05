class Observation < ApplicationRecord
  belongs_to :user
  has_many :part_impressions, dependent: :restrict_with_error, inverse_of: :observation
  has_many :activity_location_selections, dependent: :restrict_with_error, inverse_of: :observation

  attr_readonly :user_id, :created_at

  normalizes :outline_key, with: ->(value) { value.to_s.strip }
  normalizes :behavior_text, with: ->(value) { value.to_s.strip.presence }

  validates :outline_key, presence: true, inclusion: { in: ->(_) { ObservationOptions.outline_keys } }
  validates :behavior_text, length: { maximum: 2000 }, allow_nil: true
  validates :content_revision, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
