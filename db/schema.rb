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

ActiveRecord::Schema[8.1].define(version: 2025_12_31_021231) do
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

  create_table "announcements", force: :cascade do |t|
    t.integer "challenge_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_announcements_on_challenge_id"
  end

  create_table "badges", force: :cascade do |t|
    t.string "badge_type"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon_path"
    t.integer "level"
    t.string "name"
    t.float "requirement_value"
    t.string "target_type"
    t.datetime "updated_at", null: false
  end

  create_table "challenge_applications", force: :cascade do |t|
    t.datetime "applied_at"
    t.integer "challenge_id", null: false
    t.datetime "created_at", null: false
    t.string "depositor_name"
    t.text "message"
    t.text "reject_reason"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["challenge_id", "user_id"], name: "index_challenge_applications_on_challenge_id_and_user_id", unique: true
    t.index ["challenge_id"], name: "index_challenge_applications_on_challenge_id"
    t.index ["user_id"], name: "index_challenge_applications_on_user_id"
  end

  create_table "challenges", force: :cascade do |t|
    t.decimal "active_rate_threshold", precision: 5, scale: 2, default: "0.8"
    t.integer "admission_type", default: 0, null: false
    t.integer "amount", default: 0, null: false
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0"
    t.decimal "bonus_threshold", precision: 5, scale: 2, default: "1.0"
    t.string "category"
    t.text "certification_goal"
    t.decimal "completion_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "cost_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "current_participants", default: 0, null: false
    t.text "custom_host_bio"
    t.json "daily_goals"
    t.json "days", default: []
    t.text "description"
    t.date "end_date", null: false
    t.integer "entry_type", default: 0, null: false
    t.integer "failure_tolerance", default: 3
    t.decimal "full_refund_threshold", precision: 5, scale: 2, default: "0.8"
    t.string "host_account"
    t.string "host_account_holder"
    t.string "host_bank"
    t.integer "host_id", null: false
    t.string "host_name"
    t.string "invitation_code"
    t.boolean "is_featured"
    t.boolean "is_official", default: false, null: false
    t.boolean "is_private", default: false, null: false
    t.string "kakao_link"
    t.integer "likes_count", default: 0, null: false
    t.integer "max_participants", default: 100, null: false
    t.string "meeting_link"
    t.boolean "mission_allow_exceptions", default: false
    t.integer "mission_frequency", default: 0, null: false
    t.boolean "mission_is_consecutive", default: false
    t.boolean "mission_is_late_detection_enabled", default: false
    t.integer "mission_late_threshold"
    t.boolean "mission_requires_host_approval", default: false
    t.integer "mission_weekly_count"
    t.integer "mode", default: 0, null: false
    t.integer "non_participating_failures_threshold", default: 3
    t.integer "original_challenge_id"
    t.integer "penalty_per_failure", default: 0
    t.string "purpose"
    t.boolean "re_verification_allowed", default: false, null: false
    t.date "recruitment_end_date"
    t.date "recruitment_start_date"
    t.date "refund_date"
    t.string "refund_timing"
    t.boolean "requires_application_message", default: false, null: false
    t.json "reward_policy"
    t.decimal "sluggish_rate_threshold", precision: 5, scale: 2, default: "0.5"
    t.date "start_date", null: false
    t.text "summary"
    t.string "thumbnail"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.boolean "v_metric"
    t.boolean "v_photo"
    t.boolean "v_simple"
    t.boolean "v_url"
    t.time "verification_end_time"
    t.time "verification_start_time"
    t.integer "verification_type", default: 0, null: false
    t.index ["category"], name: "index_challenges_on_category"
    t.index ["host_id"], name: "index_challenges_on_host_id"
    t.index ["invitation_code"], name: "index_challenges_on_invitation_code", unique: true
    t.index ["is_official"], name: "index_challenges_on_is_official"
    t.index ["mode"], name: "index_challenges_on_mode"
    t.index ["original_challenge_id"], name: "index_challenges_on_original_challenge_id"
  end

  create_table "meeting_infos", force: :cascade do |t|
    t.string "address"
    t.integer "challenge_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "max_attendees", default: 10
    t.string "meeting_time"
    t.string "place_name", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_meeting_infos_on_challenge_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "is_read", default: false, null: false
    t.string "link"
    t.integer "notification_type", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "is_read"], name: "index_notifications_on_user_id_and_is_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "participants", force: :cascade do |t|
    t.integer "challenge_id", null: false
    t.decimal "completion_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "consecutive_failures", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "current_streak", default: 0, null: false
    t.datetime "joined_at", null: false
    t.integer "max_streak", default: 0, null: false
    t.string "nickname"
    t.integer "paid_amount", default: 0, null: false
    t.string "profile_image"
    t.string "refund_account_name"
    t.string "refund_account_number"
    t.datetime "refund_applied_at"
    t.string "refund_bank_name"
    t.integer "refund_status"
    t.integer "status", default: 0, null: false
    t.boolean "today_verified", default: false, null: false
    t.integer "total_failures", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["challenge_id"], name: "index_participants_on_challenge_id"
    t.index ["status"], name: "index_participants_on_status"
    t.index ["user_id", "challenge_id"], name: "index_participants_on_user_id_and_challenge_id", unique: true
    t.index ["user_id"], name: "index_participants_on_user_id"
  end

  create_table "personal_routine_completions", force: :cascade do |t|
    t.date "completed_on"
    t.datetime "created_at", null: false
    t.integer "personal_routine_id", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_on"], name: "index_personal_routine_completions_on_completed_on"
    t.index ["personal_routine_id"], name: "index_personal_routine_completions_on_personal_routine_id"
  end

  create_table "personal_routines", force: :cascade do |t|
    t.string "category"
    t.string "color", default: "bg-indigo-500"
    t.datetime "created_at", null: false
    t.integer "current_streak", default: 0, null: false
    t.json "days", default: []
    t.string "icon", default: "✨"
    t.date "last_completed_date"
    t.string "title", null: false
    t.integer "total_completions", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "title"], name: "index_personal_routines_on_user_id_and_title"
    t.index ["user_id"], name: "index_personal_routines_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "challenge_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "edit_count", default: 0
    t.integer "likes_count", default: 0, null: false
    t.integer "rating", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["challenge_id", "user_id"], name: "index_reviews_on_challenge_id_and_user_id", unique: true
    t.index ["challenge_id"], name: "index_reviews_on_challenge_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "staffs", force: :cascade do |t|
    t.integer "challenge_id", null: false
    t.datetime "created_at", null: false
    t.string "nickname"
    t.integer "staff_role"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["challenge_id"], name: "index_staffs_on_challenge_id"
    t.index ["user_id"], name: "index_staffs_on_user_id"
  end

  create_table "user_badges", force: :cascade do |t|
    t.integer "badge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "granted_at"
    t.boolean "is_viewed", default: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["badge_id"], name: "index_user_badges_on_badge_id"
    t.index ["user_id"], name: "index_user_badges_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.decimal "avg_completion_rate", precision: 5, scale: 2, default: "0.0"
    t.text "bio"
    t.integer "completed_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "email_verification_sent_at"
    t.string "email_verification_token"
    t.boolean "email_verified", default: false, null: false
    t.decimal "host_avg_completion_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "host_completed_challenges", default: 0
    t.integer "host_total_participants", default: 0
    t.boolean "is_featured_host"
    t.integer "level", default: 1, null: false
    t.string "nickname", null: false
    t.integer "ongoing_count", default: 0, null: false
    t.string "password_digest"
    t.string "profile_image"
    t.integer "role", default: 0, null: false
    t.string "saved_account_holder"
    t.string "saved_account_number"
    t.string "saved_bank_name"
    t.json "sns_links", default: {}
    t.integer "total_exp", default: 0, null: false
    t.integer "total_refunded", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "wallet_balance", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_verification_token"], name: "index_users_on_email_verification_token", unique: true
    t.index ["nickname"], name: "index_users_on_nickname"
  end

  create_table "verification_logs", force: :cascade do |t|
    t.integer "challenge_id", null: false
    t.datetime "created_at", null: false
    t.string "image_url"
    t.boolean "is_late", default: false, null: false
    t.integer "participant_id", null: false
    t.json "reactions", default: []
    t.string "reject_reason"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.integer "verification_type", default: 0, null: false
    t.index ["challenge_id", "created_at"], name: "index_verification_logs_on_challenge_id_and_created_at"
    t.index ["challenge_id"], name: "index_verification_logs_on_challenge_id"
    t.index ["participant_id"], name: "index_verification_logs_on_participant_id"
    t.index ["status"], name: "index_verification_logs_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcements", "challenges"
  add_foreign_key "challenge_applications", "challenges"
  add_foreign_key "challenge_applications", "users"
  add_foreign_key "challenges", "challenges", column: "original_challenge_id"
  add_foreign_key "challenges", "users", column: "host_id"
  add_foreign_key "meeting_infos", "challenges"
  add_foreign_key "notifications", "users"
  add_foreign_key "participants", "challenges"
  add_foreign_key "participants", "users"
  add_foreign_key "personal_routine_completions", "personal_routines"
  add_foreign_key "personal_routines", "users"
  add_foreign_key "reviews", "challenges"
  add_foreign_key "reviews", "users"
  add_foreign_key "staffs", "challenges"
  add_foreign_key "staffs", "users"
  add_foreign_key "user_badges", "badges"
  add_foreign_key "user_badges", "users"
  add_foreign_key "verification_logs", "challenges"
  add_foreign_key "verification_logs", "participants"
end
