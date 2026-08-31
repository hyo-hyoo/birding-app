class CreateEmailVerificationTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :email_verification_tokens, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=InnoDB" do |t|
      t.bigint :user_id, null: false
      t.string :token_digest, limit: 64, null: false, collation: "utf8mb4_0900_bin"
      t.integer :active_slot, limit: 1
      t.datetime :expires_at, precision: 6, null: false
      t.datetime :invalidated_at, precision: 6
      t.string :invalidation_reason, limit: 16, collation: "utf8mb4_0900_bin"
      t.timestamps precision: 6, null: false

      t.index :token_digest, unique: true, name: "uq_email_verification_digest"
      t.index [ :user_id, :active_slot ], unique: true, name: "uq_email_verification_active_user"
      t.index [ :expires_at, :id ], name: "ix_email_verification_expiry"
      t.index [ :invalidated_at, :id ], name: "ix_email_verification_invalidation"
      t.foreign_key :users, on_delete: :restrict, on_update: :restrict
      t.check_constraint "REGEXP_LIKE(token_digest, '^[0-9a-f]{64}$', 'c')", name: "chk_email_verification_digest"
      t.check_constraint "expires_at > created_at", name: "chk_email_verification_expiry"
      t.check_constraint <<~SQL.squish, name: "chk_email_verification_state"
        (active_slot IS NOT NULL AND active_slot = 1
          AND invalidated_at IS NULL AND invalidation_reason IS NULL)
        OR
        (active_slot IS NULL AND invalidated_at IS NOT NULL
          AND invalidation_reason IS NOT NULL
          AND invalidation_reason IN ('consumed', 'superseded'))
      SQL
    end
  end
end
