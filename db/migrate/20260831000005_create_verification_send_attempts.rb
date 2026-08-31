class CreateVerificationSendAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :verification_send_attempts, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=InnoDB" do |t|
      t.bigint :verification_rate_limit_key_id, null: false
      t.string :kind, limit: 16, null: false, collation: "utf8mb4_0900_bin"
      t.boolean :rate_limit_passed, null: false, default: false
      t.datetime :created_at, precision: 6, null: false

      t.index [ :verification_rate_limit_key_id, :created_at, :id ], name: "ix_verification_attempt_subject_time"
      t.index [ :created_at, :id ], name: "ix_verification_attempt_time"
      t.foreign_key :verification_rate_limit_keys, on_delete: :restrict, on_update: :restrict
      t.check_constraint "kind IN ('initial', 'resend')", name: "chk_verification_attempt_kind"
      t.check_constraint "rate_limit_passed IN (0, 1)", name: "chk_verification_attempt_admission"
    end
  end
end
