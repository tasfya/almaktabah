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

ActiveRecord::Schema[8.1].define(version: 2026_11_13_170000) do
  create_table "action_logs", force: :cascade do |t|
    t.string "action"
    t.integer "actionable_id", null: false
    t.string "actionable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actionable_type", "actionable_id"], name: "index_action_logs_on_actionable"
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.string "slug"
    t.string "source_url"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["category"], name: "index_articles_on_category"
    t.index ["published"], name: "index_articles_on_published"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["source_url"], name: "index_articles_on_source_url"
  end

  create_table "attempt_answers", force: :cascade do |t|
    t.integer "exam_attempt_id", null: false
    t.integer "question_id", null: false
    t.integer "choice_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["choice_id"], name: "index_attempt_answers_on_choice_id"
    t.index ["exam_attempt_id", "question_id"], name: "index_attempt_answers_on_exam_attempt_id_and_question_id", unique: true
    t.index ["question_id"], name: "index_attempt_answers_on_question_id"
  end

  create_table "books", force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "downloads", default: 0
    t.integer "pages"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_books_on_author_id"
    t.index ["category"], name: "index_books_on_category"
    t.index ["published"], name: "index_books_on_published"
    t.index ["slug"], name: "index_books_on_slug", unique: true
    t.index ["title"], name: "index_books_on_title"
  end

  create_table "certificates", force: :cascade do |t|
    t.integer "enrollment_id"
    t.integer "domain_id", null: false
    t.string "number", null: false
    t.datetime "issued_at", null: false
    t.string "full_name_snapshot", null: false
    t.string "gender_snapshot", null: false
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_certificates_on_domain_id"
    t.index ["enrollment_id"], name: "index_certificates_on_enrollment_id", unique: true
    t.index ["number"], name: "index_certificates_on_number", unique: true
  end

  create_table "choices", force: :cascade do |t|
    t.integer "question_id", null: false
    t.integer "position", null: false
    t.text "body", null: false
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id", "position"], name: "index_choices_on_question_id_and_position", unique: true
    t.index ["question_id"], name: "index_choices_on_question_id"
  end

  create_table "cohort_slots", force: :cascade do |t|
    t.integer "cohort_id", null: false
    t.integer "program_item_id", null: false
    t.date "available_on", null: false
    t.datetime "opens_at"
    t.datetime "closes_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort_id", "available_on"], name: "index_cohort_slots_on_cohort_id_and_available_on"
    t.index ["cohort_id", "program_item_id"], name: "index_cohort_slots_on_cohort_id_and_program_item_id", unique: true
    t.index ["program_item_id"], name: "index_cohort_slots_on_program_item_id"
  end

  create_table "cohorts", force: :cascade do |t|
    t.integer "program_id", null: false
    t.string "name", null: false
    t.date "starts_on", null: false
    t.string "time_zone", default: "Asia/Riyadh", null: false
    t.datetime "enrollment_closes_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_cohorts_on_program_id"
  end

  create_table "domain_assignments", force: :cascade do |t|
    t.integer "assignable_id", null: false
    t.string "assignable_type", null: false
    t.datetime "created_at", null: false
    t.integer "domain_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assignable_type", "assignable_id"], name: "index_domain_assignments_on_assignable"
    t.index ["domain_id"], name: "index_domain_assignments_on_domain_id"
  end

  create_table "domains", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.text "custom_css"
    t.text "description"
    t.string "host"
    t.boolean "is_default", default: false, null: false
    t.string "name"
    t.string "podcast_artwork_url_override"
    t.string "podcast_author"
    t.string "podcast_category", default: "Religion & Spirituality"
    t.text "podcast_description"
    t.boolean "podcast_enabled", default: false, null: false
    t.string "podcast_language", default: "ar"
    t.string "podcast_owner_email"
    t.string "podcast_owner_name"
    t.string "podcast_subcategory", default: "Islam"
    t.string "podcast_title"
    t.string "template_name", default: "default", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "youtube_url"
    t.string "x_url"
    t.index ["is_default"], name: "index_domains_on_is_default", unique: true, where: "is_default = true"
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "learner_id", null: false
    t.integer "cohort_id", null: false
    t.integer "domain_id", null: false
    t.datetime "enrolled_at", null: false
    t.datetime "completed_at"
    t.boolean "reminders_enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort_id"], name: "index_enrollments_on_cohort_id"
    t.index ["domain_id"], name: "index_enrollments_on_domain_id"
    t.index ["learner_id", "cohort_id"], name: "index_enrollments_on_learner_id_and_cohort_id", unique: true
  end

  create_table "exam_attempts", force: :cascade do |t|
    t.integer "enrollment_id", null: false
    t.integer "exam_id", null: false
    t.datetime "started_at", null: false
    t.datetime "submitted_at"
    t.integer "score_percent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_id", "exam_id"], name: "index_exam_attempts_on_enrollment_id_and_exam_id", unique: true
    t.index ["exam_id"], name: "index_exam_attempts_on_exam_id"
  end

  create_table "exams", force: :cascade do |t|
    t.integer "program_id", null: false
    t.string "title", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_exams_on_program_id"
  end

  create_table "fatwas", force: :cascade do |t|
    t.integer "audio_review_status", default: 0, null: false
    t.datetime "audio_verified_at"
    t.string "category"
    t.datetime "created_at", null: false
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.integer "scholar_id", null: false
    t.string "slug"
    t.string "source_url"
    t.string "title"
    t.text "transcription_json"
    t.datetime "updated_at", null: false
    t.index ["audio_verified_at"], name: "index_fatwas_on_audio_verified_at"
    t.index ["published"], name: "index_fatwas_on_published"
    t.index ["scholar_id"], name: "index_fatwas_on_scholar_id"
    t.index ["slug"], name: "index_fatwas_on_slug", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "learners", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "full_name", null: false
    t.integer "gender", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "domain_id"
    t.index ["confirmation_token"], name: "index_learners_on_confirmation_token", unique: true
    t.index ["domain_id"], name: "index_learners_on_domain_id"
    t.index ["email"], name: "index_learners_on_email", unique: true
    t.index ["reset_password_token"], name: "index_learners_on_reset_password_token", unique: true
  end

  create_table "lectures", force: :cascade do |t|
    t.integer "audio_review_status", default: 0, null: false
    t.datetime "audio_verified_at"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration"
    t.integer "kind"
    t.integer "old_id"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.integer "scholar_id"
    t.string "slug"
    t.string "source_url"
    t.string "title"
    t.text "transcription_json"
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.string "youtube_url"
    t.index ["audio_verified_at"], name: "index_lectures_on_audio_verified_at"
    t.index ["kind"], name: "index_lectures_on_kind"
    t.index ["old_id"], name: "index_lectures_on_old_id"
    t.index ["published"], name: "index_lectures_on_published"
    t.index ["scholar_id"], name: "index_lectures_on_scholar_id"
    t.index ["slug"], name: "index_lectures_on_slug", unique: true
    t.index ["title"], name: "index_lectures_on_title"
  end

  create_table "lesson_completions", force: :cascade do |t|
    t.integer "enrollment_id", null: false
    t.integer "program_item_id", null: false
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_id", "program_item_id"], name: "index_lesson_completions_on_enrollment_id_and_program_item_id", unique: true
    t.index ["program_item_id"], name: "index_lesson_completions_on_program_item_id"
  end

  create_table "lessons", force: :cascade do |t|
    t.integer "audio_review_status", default: 0, null: false
    t.datetime "audio_verified_at"
    t.string "content_type", default: "audio"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration"
    t.integer "old_id"
    t.integer "position"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.integer "series_id"
    t.string "source_url"
    t.string "title", null: false
    t.text "transcription_json"
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.string "youtube_url"
    t.index ["audio_verified_at"], name: "index_lessons_on_audio_verified_at"
    t.index ["old_id"], name: "index_lessons_on_old_id"
    t.index ["position"], name: "index_lessons_on_position"
    t.index ["published"], name: "index_lessons_on_published"
    t.index ["series_id"], name: "index_lessons_on_series_id"
    t.index ["title"], name: "index_lessons_on_title"
  end

  create_table "news", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.integer "scholar_id", null: false
    t.string "slug", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["published"], name: "index_news_on_published"
    t.index ["scholar_id"], name: "index_news_on_scholar_id"
    t.index ["slug"], name: "index_news_on_slug", unique: true
  end

  create_table "program_items", force: :cascade do |t|
    t.integer "program_id", null: false
    t.integer "position", null: false
    t.integer "kind", null: false
    t.integer "lesson_id"
    t.integer "book_id"
    t.integer "exam_id"
    t.string "title_override"
    t.boolean "hidden", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_program_items_on_book_id"
    t.index ["exam_id"], name: "index_program_items_on_exam_id"
    t.index ["lesson_id"], name: "index_program_items_on_lesson_id"
    t.index ["program_id", "position"], name: "index_program_items_on_program_id_and_position", unique: true
    t.index ["program_id"], name: "index_program_items_on_program_id"
    t.check_constraint "(CASE WHEN lesson_id IS NULL THEN 0 ELSE 1 END + CASE WHEN book_id IS NULL THEN 0 ELSE 1 END + CASE WHEN exam_id IS NULL THEN 0 ELSE 1 END) = 1", name: "program_items_exactly_one_reference"
  end

  create_table "programs", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug"
    t.text "description"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.integer "pass_mark", default: 60, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_programs_on_slug", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.integer "exam_id", null: false
    t.integer "position", null: false
    t.text "body", null: false
    t.integer "kind", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id", "position"], name: "index_questions_on_exam_id_and_position", unique: true
    t.index ["exam_id"], name: "index_questions_on_exam_id"
  end

  create_table "reminder_deliveries", force: :cascade do |t|
    t.integer "enrollment_id", null: false
    t.date "local_date", null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_id", "local_date"], name: "index_reminder_deliveries_on_enrollment_id_and_local_date", unique: true
  end

  create_table "scholars", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "default_domain_id"
    t.string "first_name"
    t.string "full_name"
    t.string "full_name_alias"
    t.string "last_name"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["default_domain_id"], name: "index_scholars_on_default_domain_id"
    t.index ["published"], name: "index_scholars_on_published"
    t.index ["slug"], name: "index_scholars_on_slug", unique: true
  end

  create_table "series", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.integer "scholar_id"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["published"], name: "index_series_on_published"
    t.index ["scholar_id"], name: "index_series_on_scholar_id"
    t.index ["slug"], name: "index_series_on_slug", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "telegram_import_records", force: :cascade do |t|
    t.string "source", null: false
    t.string "external_id", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.string "outcome", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_telegram_import_records_on_record"
    t.index ["source", "external_id"], name: "index_telegram_import_records_on_source_and_external_id", unique: true
  end

  create_table "track_series", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position"
    t.integer "series_id", null: false
    t.integer "track_id", null: false
    t.datetime "updated_at", null: false
    t.index ["series_id"], name: "index_track_series_on_series_id"
    t.index ["track_id"], name: "index_track_series_on_track_id"
  end

  create_table "tracks", force: :cascade do |t|
    t.integer "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "difficulty_level"
    t.integer "estimated_hours"
    t.integer "position"
    t.boolean "published"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "user_scholars", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "scholar_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["scholar_id"], name: "index_user_scholars_on_scholar_id"
    t.index ["user_id"], name: "index_user_scholars_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "articles", "scholars", column: "author_id"
  add_foreign_key "attempt_answers", "choices"
  add_foreign_key "attempt_answers", "exam_attempts"
  add_foreign_key "attempt_answers", "questions"
  add_foreign_key "books", "scholars", column: "author_id"
  add_foreign_key "certificates", "domains"
  add_foreign_key "certificates", "enrollments", on_delete: :nullify
  add_foreign_key "choices", "questions"
  add_foreign_key "cohort_slots", "cohorts"
  add_foreign_key "cohort_slots", "program_items"
  add_foreign_key "cohorts", "programs"
  add_foreign_key "domain_assignments", "domains"
  add_foreign_key "enrollments", "cohorts"
  add_foreign_key "enrollments", "domains"
  add_foreign_key "enrollments", "learners"
  add_foreign_key "exam_attempts", "enrollments"
  add_foreign_key "exam_attempts", "exams"
  add_foreign_key "exams", "programs"
  add_foreign_key "fatwas", "scholars"
  add_foreign_key "learners", "domains", on_delete: :nullify
  add_foreign_key "lectures", "scholars"
  add_foreign_key "lesson_completions", "enrollments"
  add_foreign_key "lesson_completions", "program_items"
  add_foreign_key "lessons", "series"
  add_foreign_key "news", "scholars"
  add_foreign_key "program_items", "books"
  add_foreign_key "program_items", "exams"
  add_foreign_key "program_items", "lessons"
  add_foreign_key "program_items", "programs"
  add_foreign_key "questions", "exams"
  add_foreign_key "reminder_deliveries", "enrollments", on_delete: :cascade
  add_foreign_key "scholars", "domains", column: "default_domain_id"
  add_foreign_key "series", "scholars"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "track_series", "series"
  add_foreign_key "track_series", "tracks"
  add_foreign_key "user_scholars", "scholars"
  add_foreign_key "user_scholars", "users"
end
