class CreateActivityLocationSelections < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_location_selections, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=InnoDB" do |t|
      t.bigint :observation_id, null: false
      t.string :location_key, limit: 64, null: false, collation: "utf8mb4_0900_bin"
      t.integer :slot, limit: 1, null: false
      t.timestamps precision: 6, null: false

      t.index [ :observation_id, :location_key ], unique: true, name: "uq_activity_locations_key"
      t.index [ :observation_id, :slot ], unique: true, name: "uq_activity_locations_slot"
      t.foreign_key :observations, on_delete: :restrict, on_update: :restrict
      t.check_constraint "CHAR_LENGTH(location_key) > 0", name: "chk_activity_locations_key"
      t.check_constraint "slot BETWEEN 1 AND 2", name: "chk_activity_locations_slot"
    end
  end
end
