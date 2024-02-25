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

ActiveRecord::Schema[7.1].define(version: 2024_02_23_160241) do
  # These are extensions that must be enabled in order to support this database
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

  create_table "user_refresh_tokens", id: false, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "token", null: false
    t.string "device", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device"], name: "index_user_refresh_tokens_on_device", using: :hash
    t.index ["token"], name: "index_user_refresh_tokens_on_token", using: :hash
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

end
