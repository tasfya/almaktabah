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

ActiveRecord::Schema[8.0].define(version: 2025_04_24_105936) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_articles_on_author_id"
  end

  create_table "benefits", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_benefits_on_tenant_id"
  end

  create_table "books", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.text "description"
    t.integer "tenant_id"
    t.datetime "published_at"
    t.integer "download_count"
    t.integer "visit_count"
    t.index ["author_id"], name: "index_books_on_author_id"
    t.index ["tenant_id"], name: "index_books_on_tenant_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categorizations", force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "categorizable_type", null: false
    t.integer "categorizable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["categorizable_type", "categorizable_id"], name: "index_categorizations_on_categorizable"
    t.index ["category_id"], name: "index_categorizations_on_category_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.text "message", null: false
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_contacts_on_tenant_id"
  end

  create_table "fatwas", force: :cascade do |t|
    t.text "question"
    t.text "answer"
    t.string "source"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_fatwas_on_tenant_id"
  end

  create_table "lectures", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.text "content", null: false
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_lectures_on_tenant_id"
  end

  create_table "lessons", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.text "content"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_lessons_on_tenant_id"
  end

  create_table "motor_resources", force: :cascade do |t|
    t.string "name", null: false
    t.text "preferences", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_motor_resources_on_name", unique: true
    t.index ["updated_at"], name: "index_motor_resources_on_updated_at"
  end

  create_table "motor_taggable_tags", force: :cascade do |t|
    t.integer "tag_id", null: false
    t.bigint "taggable_id", null: false
    t.string "taggable_type", null: false
    t.index ["tag_id"], name: "index_motor_taggable_tags_on_tag_id"
    t.index ["taggable_id", "taggable_type", "tag_id"], name: "motor_polymorphic_association_tag_index", unique: true
  end

  create_table "motor_tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "motor_tags_name_unique_index", unique: true
  end

  create_table "scholars", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "speeches", force: :cascade do |t|
    t.string "title"
    t.string "speaker"
    t.string "event"
    t.date "date"
    t.text "content"
    t.integer "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_speeches_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "subdomain"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "articles", "scholars", column: "author_id"
  add_foreign_key "benefits", "tenants"
  add_foreign_key "books", "scholars", column: "author_id"
  add_foreign_key "books", "tenants"
  add_foreign_key "categorizations", "categories"
  add_foreign_key "contacts", "tenants"
  add_foreign_key "fatwas", "tenants"
  add_foreign_key "lectures", "tenants"
  add_foreign_key "lessons", "tenants"
  add_foreign_key "motor_taggable_tags", "motor_tags", column: "tag_id"
  add_foreign_key "speeches", "tenants"
end
