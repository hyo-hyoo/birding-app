class CreateVerificationRateLimitKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :verification_rate_limit_keys, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=InnoDB" do |t|
      t.string :scope, limit: 16, null: false, collation: "utf8mb4_0900_bin"
      t.string :subject_digest, limit: 64, null: false, collation: "utf8mb4_0900_bin"
      t.timestamps precision: 6, null: false

      t.index [ :scope, :subject_digest ], unique: true, name: "uq_verification_rate_subject"
      t.check_constraint "scope IN ('email', 'ip')", name: "chk_verification_rate_scope"
      t.check_constraint "REGEXP_LIKE(subject_digest, '^[0-9a-f]{64}$', 'c')", name: "chk_verification_rate_digest"
    end
  end
end
