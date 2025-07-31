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

ActiveRecord::Schema[8.0].define(version: 2025_07_31_091454) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
  end

  create_table "editors", force: :cascade do |t|
    t.string "name", null: false
    t.string "client_id", null: false
    t.string "client_secret", null: false
    t.boolean "authorized", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_editors_on_client_id", unique: true
    t.index ["name"], name: "index_editors_on_name", unique: true
  end

  create_table "market_attributes", force: :cascade do |t|
    t.string "key", null: false
    t.integer "input_type", default: 0, null: false
    t.string "category_key", null: false
    t.string "subcategory_key", null: false
    t.boolean "from_api", default: false, null: false
    t.boolean "required", default: false, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_market_attributes_on_deleted_at"
    t.index ["input_type"], name: "index_market_attributes_on_input_type"
    t.index ["key"], name: "index_market_attributes_on_key", unique: true
    t.index ["required"], name: "index_market_attributes_on_required"
  end

  create_table "market_attributes_public_markets", id: false, force: :cascade do |t|
    t.bigint "public_market_id", null: false
    t.bigint "market_attribute_id", null: false
    t.index ["market_attribute_id", "public_market_id"], name: "index_market_attributes_public_markets_lookup"
    t.index ["public_market_id", "market_attribute_id"], name: "index_public_markets_attributes_unique", unique: true
  end

  create_table "market_attributes_types", id: false, force: :cascade do |t|
    t.bigint "market_type_id", null: false
    t.bigint "market_attribute_id", null: false
    t.index ["market_attribute_id", "market_type_id"], name: "index_market_attributes_types_lookup"
    t.index ["market_type_id", "market_attribute_id"], name: "index_market_types_attributes_unique", unique: true
  end

  create_table "market_types", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_market_types_on_code", unique: true
    t.index ["deleted_at"], name: "index_market_types_on_deleted_at"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "public_markets", force: :cascade do |t|
    t.string "identifier", null: false
    t.bigint "editor_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "lot_name"
    t.datetime "deadline"
    t.string "market_type"
    t.boolean "defense_industry"
    t.text "selected_optional_fields", default: [], array: true
    t.text "market_type_codes", default: [], array: true
    t.index ["editor_id"], name: "index_public_markets_on_editor_id"
    t.index ["identifier"], name: "index_public_markets_on_identifier", unique: true
    t.index ["selected_optional_fields"], name: "index_public_markets_on_selected_optional_fields", using: :gin
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "public_markets", "editors"
end
