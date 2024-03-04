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

ActiveRecord::Schema[7.1].define(version: 2024_03_01_183409) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "refresh_tokens", id: false, force: :cascade do |t|
    t.uuid "user_id"
    t.text "token"
    t.text "device"
    t.text "action"
    t.text "reason"
    t.datetime "expire_at", precision: nil
    t.datetime "created_at", precision: nil
  end

  create_table "user_emails", force: :cascade do |t|
    t.uuid "user_id"
    t.citext "email", null: false
    t.boolean "validated_otp", default: false
    t.string "otp_tail", default: "", null: false
    t.string "otp_secret_key", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_user_emails_on_email", unique: true
    t.index ["user_id"], name: "index_user_emails_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "password"
    t.string "password_digest"
    t.string "first_name", null: false
    t.string "last_name"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "user_emails", "users"
end
