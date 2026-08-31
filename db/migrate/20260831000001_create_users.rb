class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", options: "ENGINE=InnoDB" do |t|
      t.string :email_address, limit: 255, null: false, collation: "utf8mb4_0900_bin"
      t.string :password_digest, limit: 255, null: false, collation: "utf8mb4_0900_bin"
      t.datetime :email_verified_at, precision: 6
      t.timestamps precision: 6, null: false

      t.index :email_address, unique: true, name: "uq_users_email"
      t.check_constraint "CHAR_LENGTH(email_address) > 0", name: "chk_users_email_present"
      t.check_constraint "CHAR_LENGTH(password_digest) > 0", name: "chk_users_password_present"
    end
  end
end
