class CreatePartImpressions < ActiveRecord::Migration[8.1]
  def change
    create_table :part_impressions, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=InnoDB" do |t|
      t.bigint :observation_id, null: false
      t.string :part_key, limit: 64, null: false, collation: "utf8mb4_0900_bin"
      t.string :primary_color_key, limit: 64, collation: "utf8mb4_0900_bin"
      t.string :secondary_color_key, limit: 64, collation: "utf8mb4_0900_bin"
      t.string :feature_key, limit: 64, collation: "utf8mb4_0900_bin"
      t.text :description
      t.string :certainty_key, limit: 16, null: false, collation: "utf8mb4_0900_bin"
      t.timestamps precision: 6, null: false

      t.index [ :observation_id, :part_key ], unique: true, name: "uq_part_impressions_part"
      t.foreign_key :observations, on_delete: :restrict, on_update: :restrict
      t.check_constraint "part_key IN ('head', 'chest_belly', 'wing', 'tail')", name: "chk_part_impressions_part"
      t.check_constraint "certainty_key IN ('certain', 'probable', 'vague')", name: "chk_part_impressions_certainty"
      t.check_constraint <<~SQL.squish, name: "chk_part_impressions_optional_keys"
        (primary_color_key IS NULL OR CHAR_LENGTH(primary_color_key) > 0)
        AND (secondary_color_key IS NULL OR CHAR_LENGTH(secondary_color_key) > 0)
        AND (feature_key IS NULL OR CHAR_LENGTH(feature_key) > 0)
      SQL
      t.check_constraint <<~SQL.squish, name: "chk_part_impressions_description"
        description IS NULL OR CHAR_LENGTH(description) BETWEEN 1 AND 2000
      SQL
      t.check_constraint <<~SQL.squish, name: "chk_part_impressions_content"
        primary_color_key IS NOT NULL OR feature_key IS NOT NULL OR description IS NOT NULL
      SQL
      t.check_constraint <<~SQL.squish, name: "chk_part_impressions_secondary_color"
        secondary_color_key IS NULL
        OR (primary_color_key IS NOT NULL AND secondary_color_key <> primary_color_key)
      SQL
    end
  end
end
