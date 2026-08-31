class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=InnoDB" do |t|
      t.bigint :user_id, null: false
      t.datetime :expires_at, precision: 6, null: false
      t.timestamps precision: 6, null: false

      t.index :user_id, name: "ix_sessions_user"
      t.index [ :expires_at, :id ], name: "ix_sessions_expiry"
      t.foreign_key :users, on_delete: :restrict, on_update: :restrict
      t.check_constraint "expires_at > created_at", name: "chk_sessions_expiry"
    end
  end
end
