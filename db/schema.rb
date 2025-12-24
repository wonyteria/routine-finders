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

ActiveRecord::Schema[8.1].define(version: 2025_12_24_082203) do
  create_table "challenges", force: :cascade do |t|
    t.integer "admission_type", default: 0, null: false
    t.integer "amount", default: 0, null: false
    t.string "category"
    t.decimal "completion_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "cost_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "current_participants", default: 0, null: false
    t.json "days", default: []
    t.text "description"
    t.date "end_date", null: false
    t.integer "entry_type", default: 0, null: false
    t.integer "failure_tolerance", default: 3
    t.string "host_account"
    t.integer "host_id", null: false
    t.string "host_name"
    t.boolean "is_official", default: false, null: false
    t.string "kakao_link"
    t.integer "max_participants", default: 100, null: false
    t.boolean "mission_allow_exceptions", default: false
    t.integer "mission_frequency", default: 0, null: false
    t.boolean "mission_is_consecutive", default: false
    t.boolean "mission_is_late_detection_enabled", default: false
    t.integer "mission_late_threshold"
    t.boolean "mission_requires_host_approval", default: false
    t.integer "mission_weekly_count"
    t.integer "mode", default: 0, null: false
    t.integer "penalty_per_failure", default: 0
    t.string "purpose"
    t.string "refund_timing"
    t.date "start_date", null: false
    t.text "summary"
    t.string "thumbnail"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "verification_type", default: 0, null: false
    t.index ["category"], name: "index_challenges_on_category"
    t.index ["host_id"], name: "index_challenges_on_host_id"
    t.index ["is_official"], name: "index_challenges_on_is_official"
    t.index ["mode"], name: "index_challenges_on_mode"
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

  create_table "users", force: :cascade do |t|
    t.decimal "avg_completion_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "completed_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.decimal "host_avg_completion_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "host_completed_challenges", default: 0
    t.integer "host_total_participants", default: 0
    t.integer "level", default: 1, null: false
    t.string "nickname", null: false
    t.integer "ongoing_count", default: 0, null: false
    t.string "profile_image"
    t.integer "role", default: 0, null: false
    t.integer "total_exp", default: 0, null: false
    t.integer "total_refunded", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "wallet_balance", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
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

  add_foreign_key "challenges", "users", column: "host_id"
  add_foreign_key "meeting_infos", "challenges"
  add_foreign_key "notifications", "users"
  add_foreign_key "participants", "challenges"
  add_foreign_key "participants", "users"
  add_foreign_key "personal_routines", "users"
  add_foreign_key "staffs", "challenges"
  add_foreign_key "staffs", "users"
  add_foreign_key "verification_logs", "challenges"
  add_foreign_key "verification_logs", "participants"
end
