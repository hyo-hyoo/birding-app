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

ActiveRecord::Schema[8.1].define(version: 2026_08_31_000002) do
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

  add_foreign_key "sessions", "users"
end
