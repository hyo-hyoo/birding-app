class ActivityLocationSelection < ApplicationRecord
  belongs_to :observation, inverse_of: :activity_location_selections

  attr_readonly :observation_id

  normalizes :location_key, with: ->(value) { value.to_s.strip }

  validates :location_key, presence: true,
    inclusion: { in: ->(_) { ObservationOptions.activity_location_keys } },
    uniqueness: { scope: :observation_id }
  validates :slot, numericality: { only_integer: true, in: 1..2 }, uniqueness: { scope: :observation_id }
end
