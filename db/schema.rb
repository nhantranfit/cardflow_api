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

ActiveRecord::Schema[7.1].define(version: 2026_08_13_165902) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "brands", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_brands_on_name", unique: true
    t.check_constraint "status = ANY (ARRAY[0, 1])", name: "brands_status_check"
  end

  create_table "client_products", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "product_id"], name: "index_client_products_on_client_id_and_product_id", unique: true
    t.index ["client_id"], name: "index_client_products_on_client_id"
    t.index ["product_id"], name: "index_client_products_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "brand_id", null: false
    t.string "name", null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.check_constraint "status = ANY (ARRAY[0, 1])", name: "products_status_check"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", null: false
    t.decimal "payout_rate", precision: 5, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.check_constraint "role::text = 'admin'::text AND payout_rate IS NULL OR role::text = 'client'::text AND payout_rate IS NOT NULL AND payout_rate > 0::numeric AND payout_rate <= 1::numeric", name: "users_payout_rate_role_check"
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying, 'client'::character varying]::text[])", name: "users_role_check"
  end

  add_foreign_key "client_products", "products"
  add_foreign_key "client_products", "users", column: "client_id"
  add_foreign_key "products", "brands"
end
