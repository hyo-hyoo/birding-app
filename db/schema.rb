# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_05_000003) do
  create_table "activity_location_selections", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location_key", limit: 64, null: false, collation: "utf8mb4_0900_bin"
    t.bigint "observation_id", null: false
    t.integer "slot", limit: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["observation_id", "location_key"], name: "uq_activity_locations_key", unique: true
    t.index ["observation_id", "slot"], name: "uq_activity_locations_slot", unique: true
    t.check_constraint "`slot` between 1 and 2", name: "chk_activity_locations_slot"
    t.check_constraint "char_length(`location_key`) > 0", name: "chk_activity_locations_key"
  end

  create_table "email_verification_tokens", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "active_slot", limit: 1
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "invalidated_at"
    t.string "invalidation_reason", limit: 16, collation: "utf8mb4_0900_bin"
    t.string "token_digest", limit: 64, null: false, collation: "utf8mb4_0900_bin"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expires_at", "id"], name: "ix_email_verification_expiry"
    t.index ["invalidated_at", "id"], name: "ix_email_verification_invalidation"
    t.index ["token_digest"], name: "uq_email_verification_digest", unique: true
    t.index ["user_id", "active_slot"], name: "uq_email_verification_active_user", unique: true
    t.check_constraint "((`active_slot` is not null) and (`active_slot` = 1) and (`invalidated_at` is null) and (`invalidation_reason` is null)) or ((`active_slot` is null) and (`invalidated_at` is not null) and (`invalidation_reason` is not null) and (`invalidation_reason` in (_utf8mb4'consumed',_utf8mb4'superseded')))", name: "chk_email_verification_state"
    t.check_constraint "`expires_at` > `created_at`", name: "chk_email_verification_expiry"
    t.check_constraint "regexp_like(`token_digest`,_utf8mb4'^[0-9a-f]{64}$',_utf8mb4'c')", name: "chk_email_verification_digest"
  end

  create_table "observations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "behavior_text"
    t.bigint "content_revision", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "outline_key", limit: 64, null: false, collation: "utf8mb4_0900_bin"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "created_at", "id"], name: "ix_observations_history"
    t.check_constraint "(`behavior_text` is null) or (char_length(`behavior_text`) between 1 and 2000)", name: "chk_observations_behavior"
    t.check_constraint "`content_revision` >= 0", name: "chk_observations_content_revision"
    t.check_constraint "char_length(`outline_key`) > 0", name: "chk_observations_outline"
  end

  create_table "part_impressions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "certainty_key", limit: 16, null: false, collation: "utf8mb4_0900_bin"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "feature_key", limit: 64, collation: "utf8mb4_0900_bin"
    t.bigint "observation_id", null: false
    t.string "part_key", limit: 64, null: false, collation: "utf8mb4_0900_bin"
    t.string "primary_color_key", limit: 64, collation: "utf8mb4_0900_bin"
    t.string "secondary_color_key", limit: 64, collation: "utf8mb4_0900_bin"
    t.datetime "updated_at", null: false
    t.index ["observation_id", "part_key"], name: "uq_part_impressions_part", unique: true
    t.check_constraint "((`primary_color_key` is null) or (char_length(`primary_color_key`) > 0)) and ((`secondary_color_key` is null) or (char_length(`secondary_color_key`) > 0)) and ((`feature_key` is null) or (char_length(`feature_key`) > 0))", name: "chk_part_impressions_optional_keys"
    t.check_constraint "(`description` is null) or (char_length(`description`) between 1 and 2000)", name: "chk_part_impressions_description"
    t.check_constraint "(`primary_color_key` is not null) or (`feature_key` is not null) or (`description` is not null)", name: "chk_part_impressions_content"
    t.check_constraint "(`secondary_color_key` is null) or ((`primary_color_key` is not null) and (`secondary_color_key` <> `primary_color_key`))", name: "chk_part_impressions_secondary_color"
    t.check_constraint "`certainty_key` in (_utf8mb4'certain',_utf8mb4'probable',_utf8mb4'vague')", name: "chk_part_impressions_certainty"
    t.check_constraint "`part_key` in (_utf8mb4'head',_utf8mb4'chest_belly',_utf8mb4'wing',_utf8mb4'tail')", name: "chk_part_impressions_part"
  end

  create_table "sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["expires_at", "id"], name: "ix_sessions_expiry"
    t.index ["user_id"], name: "ix_sessions_user"
    t.check_constraint "`expires_at` > `created_at`", name: "chk_sessions_expiry"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false, collation: "utf8mb4_0900_bin"
    t.datetime "email_verified_at"
    t.string "password_digest", null: false, collation: "utf8mb4_0900_bin"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "uq_users_email", unique: true
    t.check_constraint "char_length(`email_address`) > 0", name: "chk_users_email_present"
    t.check_constraint "char_length(`password_digest`) > 0", name: "chk_users_password_present"
  end

  create_table "verification_rate_limit_keys", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "scope", limit: 16, null: false, collation: "utf8mb4_0900_bin"
    t.string "subject_digest", limit: 64, null: false, collation: "utf8mb4_0900_bin"
    t.datetime "updated_at", null: false
    t.index ["scope", "subject_digest"], name: "uq_verification_rate_subject", unique: true
    t.check_constraint "`scope` in (_utf8mb4'email',_utf8mb4'ip')", name: "chk_verification_rate_scope"
    t.check_constraint "regexp_like(`subject_digest`,_utf8mb4'^[0-9a-f]{64}$',_utf8mb4'c')", name: "chk_verification_rate_digest"
  end

  create_table "verification_send_attempts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind", limit: 16, null: false, collation: "utf8mb4_0900_bin"
    t.boolean "rate_limit_passed", default: false, null: false
    t.bigint "verification_rate_limit_key_id", null: false
    t.index ["created_at", "id"], name: "ix_verification_attempt_time"
    t.index ["verification_rate_limit_key_id", "created_at", "id"], name: "ix_verification_attempt_subject_time"
    t.check_constraint "`kind` in (_utf8mb4'initial',_utf8mb4'resend')", name: "chk_verification_attempt_kind"
    t.check_constraint "`rate_limit_passed` in (0,1)", name: "chk_verification_attempt_admission"
  end

  add_foreign_key "activity_location_selections", "observations"
  add_foreign_key "email_verification_tokens", "users"
  add_foreign_key "observations", "users"
  add_foreign_key "part_impressions", "observations"
  add_foreign_key "sessions", "users"
  add_foreign_key "verification_send_attempts", "verification_rate_limit_keys"
end
