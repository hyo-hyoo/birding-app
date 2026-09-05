class CreateObservations < ActiveRecord::Migration[8.1]
  def change
    create_table :observations, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=InnoDB" do |t|
      t.bigint :user_id, null: false
      t.string :outline_key, limit: 64, null: false, collation: "utf8mb4_0900_bin"
      t.text :behavior_text
      t.bigint :content_revision, null: false, default: 0
      t.timestamps precision: 6, null: false

      t.index [ :user_id, :created_at, :id ], name: "ix_observations_history"
      t.foreign_key :users, on_delete: :restrict, on_update: :restrict
      t.check_constraint "CHAR_LENGTH(outline_key) > 0", name: "chk_observations_outline"
      t.check_constraint "content_revision >= 0", name: "chk_observations_content_revision"
      t.check_constraint <<~SQL.squish, name: "chk_observations_behavior"
        behavior_text IS NULL OR CHAR_LENGTH(behavior_text) BETWEEN 1 AND 2000
      SQL
    end
  end
end
