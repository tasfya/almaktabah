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

ActiveRecord::Schema[8.0].define(version: 2025_08_27_064112) do
  create_table "action_logs", force: :cascade do |t|
    t.string "action"
    t.string "actionable_type", null: false
    t.integer "actionable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actionable_type", "actionable_id"], name: "index_action_logs_on_actionable"
  end

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
    t.boolean "published", default: false, null: false
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["published"], name: "index_articles_on_published"
  end

  create_table "benefits", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "category"
    t.integer "duration", default: 0
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: false, null: false
    t.integer "scholar_id"
    t.index ["published"], name: "index_benefits_on_published"
    t.index ["scholar_id"], name: "index_benefits_on_scholar_id"
  end

  create_table "books", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.text "description"
    t.string "category"
    t.datetime "published_at"
    t.integer "downloads", default: 0
    t.integer "pages"
    t.boolean "published", default: false, null: false
    t.index ["author_id"], name: "index_books_on_author_id"
    t.index ["category"], name: "index_books_on_category"
    t.index ["published"], name: "index_books_on_published"
    t.index ["title"], name: "index_books_on_title"
  end

  create_table "domain_assignments", force: :cascade do |t|
    t.string "assignable_type", null: false
    t.integer "assignable_id", null: false
    t.integer "domain_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignable_type", "assignable_id"], name: "index_domain_assignments_on_assignable"
    t.index ["domain_id"], name: "index_domain_assignments_on_domain_id"
  end

  create_table "domains", force: :cascade do |t|
    t.string "name"
    t.string "host"
    t.text "description"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "custom_css"
    t.string "template_name", default: "default", null: false
  end

  create_table "fatwas", force: :cascade do |t|
    t.string "title"
    t.string "category"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: false, null: false
    t.index ["published"], name: "index_fatwas_on_published"
  end

  create_table "lectures", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "duration"
    t.string "category"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.integer "old_id"
    t.string "youtube_url"
    t.boolean "published", default: false, null: false
    t.integer "scholar_id"
    t.string "source_url"
    t.integer "kind"
    t.index ["kind"], name: "index_lectures_on_kind"
    t.index ["old_id"], name: "index_lectures_on_old_id"
    t.index ["published"], name: "index_lectures_on_published"
    t.index ["scholar_id"], name: "index_lectures_on_scholar_id"
    t.index ["title"], name: "index_lectures_on_title"
  end

  create_table "lessons", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "published_at"
    t.integer "duration"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "content_type", default: "audio"
    t.integer "series_id"
    t.string "video_url"
    t.integer "old_id"
    t.string "youtube_url"
    t.integer "position"
    t.boolean "published", default: false, null: false
    t.string "source_url"
    t.index ["old_id"], name: "index_lessons_on_old_id"
    t.index ["position"], name: "index_lessons_on_position"
    t.index ["published"], name: "index_lessons_on_published"
    t.index ["series_id"], name: "index_lessons_on_series_id"
    t.index ["title"], name: "index_lessons_on_title"
  end

  create_table "news", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "published_at"
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: false, null: false
    t.index ["published"], name: "index_news_on_published"
    t.index ["slug"], name: "index_news_on_slug", unique: true
  end

  create_table "scholars", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.string "full_name"
    t.string "full_name_alias"
    t.index ["published"], name: "index_scholars_on_published"
  end

  create_table "series", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "published_at"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: false, null: false
    t.integer "scholar_id"
    t.index ["published"], name: "index_series_on_published"
    t.index ["scholar_id"], name: "index_series_on_scholar_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "articles", "scholars", column: "author_id"
  add_foreign_key "benefits", "scholars"
  add_foreign_key "books", "scholars", column: "author_id"
  add_foreign_key "domain_assignments", "domains"
  add_foreign_key "lectures", "scholars"
  add_foreign_key "lessons", "series"
  add_foreign_key "series", "scholars"
end
