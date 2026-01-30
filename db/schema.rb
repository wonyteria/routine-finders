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

ActiveRecord::Schema[8.1].define(version: 2026_01_30_180708) do
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
    t.integer "challenge_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "routine_club_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_announcements_on_challenge_id"
    t.index ["routine_club_id"], name: "index_announcements_on_routine_club_id"
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

  create_table "banners", force: :cascade do |t|
    t.boolean "active"
    t.string "badge_text"
    t.integer "banner_type"
    t.datetime "created_at", null: false
    t.string "link_url"
    t.integer "priority"
    t.string "subtitle"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "challenge_applications", force: :cascade do |t|
    t.datetime "applied_at"
    t.integer "challenge_id", null: false
    t.string "contact_info"
    t.datetime "created_at", null: false
    t.string "depositor_name"
    t.text "message"
    t.string "refund_account_name"
    t.string "refund_account_number"
    t.string "refund_bank_name"
    t.text "reject_reason"
    t.integer "status", default: 0, null: false
    t.string "threads_nickname"
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
    t.text "application_question"
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0"
    t.decimal "bonus_threshold", precision: 5, scale: 2, default: "1.0"
    t.string "category"
    t.text "certification_goal"
    t.string "chat_link"
    t.decimal "completion_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "cost_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "current_participants", default: 0, null: false
    t.text "custom_host_bio"
    t.json "daily_goals"
    t.json "days", default: []
    t.text "description"
    t.integer "duration_minutes"
    t.date "end_date", null: false
    t.integer "entry_type", default: 0, null: false
    t.integer "failure_tolerance", default: 3
    t.decimal "full_refund_threshold", precision: 5, scale: 2, default: "0.8"
    t.string "host_account"
    t.string "host_account_holder"
    t.string "host_bank"
    t.integer "host_id", null: false
    t.string "host_name"
    t.string "host_phone"
    t.string "invitation_code"
    t.boolean "is_featured"
    t.boolean "is_official", default: false, null: false
    t.boolean "is_private", default: false, null: false
    t.string "kakao_link"
    t.integer "likes_count", default: 0, null: false
    t.integer "max_participants", default: 100, null: false
    t.string "meeting_frequency"
    t.string "meeting_link"
    t.integer "meeting_type"
    t.integer "min_participants"
    t.boolean "mission_allow_exceptions", default: false
    t.integer "mission_frequency", default: 0, null: false
    t.boolean "mission_is_consecutive", default: false
    t.boolean "mission_is_late_detection_enabled", default: false
    t.integer "mission_late_threshold"
    t.boolean "mission_requires_host_approval", default: false
    t.integer "mission_weekly_count"
    t.integer "mode", default: 0, null: false
    t.integer "non_participating_failures_threshold", default: 3
    t.string "online_meeting_link"
    t.integer "original_challenge_id"
    t.integer "participation_fee"
    t.integer "penalty_per_failure", default: 0
    t.text "preparation_items"
    t.string "purpose"
    t.boolean "re_verification_allowed", default: false, null: false
    t.date "recruitment_end_date"
    t.date "recruitment_start_date"
    t.date "refund_date"
    t.text "refund_policy"
    t.string "refund_timing"
    t.boolean "requires_application_message", default: false, null: false
    t.json "reward_policy"
    t.decimal "sluggish_rate_threshold", precision: 5, scale: 2, default: "0.5"
    t.date "start_date", null: false
    t.integer "status", default: 0, null: false
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
    t.index ["current_participants"], name: "index_challenges_on_current_participants"
    t.index ["end_date", "created_at"], name: "index_challenges_on_end_date_and_created_at"
    t.index ["end_date"], name: "index_challenges_on_end_date"
    t.index ["host_id"], name: "index_challenges_on_host_id"
    t.index ["invitation_code"], name: "index_challenges_on_invitation_code", unique: true
    t.index ["is_official"], name: "index_challenges_on_is_official"
    t.index ["mode"], name: "index_challenges_on_mode"
    t.index ["original_challenge_id"], name: "index_challenges_on_original_challenge_id"
    t.index ["recruitment_end_date"], name: "index_challenges_on_recruitment_end_date"
    t.index ["status"], name: "index_challenges_on_status"
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
    t.string "contact_info"
    t.datetime "created_at", null: false
    t.integer "current_streak", default: 0, null: false
    t.decimal "final_achievement_rate", precision: 5, scale: 2
    t.datetime "joined_at", null: false
    t.integer "max_streak", default: 0, null: false
    t.string "nickname"
    t.integer "paid_amount", default: 0, null: false
    t.string "profile_image"
    t.string "refund_account_name"
    t.string "refund_account_number"
    t.integer "refund_amount", default: 0
    t.datetime "refund_applied_at"
    t.string "refund_bank_name"
    t.integer "refund_status"
    t.integer "status", default: 0, null: false
    t.string "threads_nickname"
    t.boolean "today_verified", default: false, null: false
    t.integer "total_failures", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["challenge_id", "status"], name: "index_participants_on_challenge_id_and_status"
    t.index ["challenge_id"], name: "index_participants_on_challenge_id"
    t.index ["completion_rate"], name: "index_participants_on_completion_rate"
    t.index ["status"], name: "index_participants_on_status"
    t.index ["user_id", "challenge_id"], name: "index_participants_on_user_id_and_challenge_id", unique: true
    t.index ["user_id", "status"], name: "index_participants_on_user_id_and_status"
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
    t.datetime "deleted_at"
    t.string "icon", default: "✨"
    t.date "last_completed_date"
    t.string "title", null: false
    t.integer "total_completions", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "created_at"], name: "index_personal_routines_on_user_id_and_created_at"
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

  create_table "routine_club_attendances", force: :cascade do |t|
    t.float "achievement_rate"
    t.date "attendance_date", null: false
    t.integer "cheers_count", default: 0
    t.json "cheers_from_users", default: []
    t.datetime "created_at", null: false
    t.string "proof_image"
    t.text "proof_text"
    t.integer "routine_club_id", null: false
    t.integer "routine_club_member_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.index ["attendance_date"], name: "index_routine_club_attendances_on_attendance_date"
    t.index ["routine_club_id"], name: "index_routine_club_attendances_on_routine_club_id"
    t.index ["routine_club_member_id", "attendance_date"], name: "index_club_attendances_on_member_and_date", unique: true
    t.index ["routine_club_member_id"], name: "index_routine_club_attendances_on_routine_club_member_id"
  end

  create_table "routine_club_gatherings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "gathering_at"
    t.integer "gathering_type"
    t.string "location"
    t.integer "max_attendees"
    t.integer "routine_club_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["routine_club_id"], name: "index_routine_club_gatherings_on_routine_club_id"
  end

  create_table "routine_club_members", force: :cascade do |t|
    t.integer "absence_count", default: 0
    t.float "achievement_rate"
    t.integer "attendance_count", default: 0
    t.decimal "attendance_rate", precision: 5, scale: 2, default: "0.0"
    t.text "commitment"
    t.string "contact_info"
    t.datetime "created_at", null: false
    t.datetime "deposit_confirmed_at"
    t.string "depositor_name"
    t.text "goal"
    t.integer "growth_points"
    t.string "identity_title"
    t.boolean "is_moderator", default: false
    t.datetime "joined_at", null: false
    t.text "kick_reason"
    t.datetime "last_pass_refill_at"
    t.date "membership_end_date", null: false
    t.date "membership_start_date", null: false
    t.integer "paid_amount", default: 0, null: false
    t.integer "payment_status", default: 0, null: false
    t.integer "penalty_count", default: 0
    t.integer "routine_club_id", null: false
    t.integer "status", default: 0, null: false
    t.string "threads_nickname"
    t.datetime "updated_at", null: false
    t.integer "used_passes_count", default: 0
    t.integer "used_relax_passes_count", default: 0
    t.integer "used_save_passes_count", default: 0
    t.integer "user_id", null: false
    t.boolean "welcomed", default: false
    t.index ["attendance_rate"], name: "index_routine_club_members_on_attendance_rate"
    t.index ["payment_status"], name: "index_routine_club_members_on_payment_status"
    t.index ["routine_club_id", "status"], name: "index_routine_club_members_on_routine_club_id_and_status"
    t.index ["routine_club_id", "user_id"], name: "index_routine_club_members_on_routine_club_id_and_user_id", unique: true
    t.index ["routine_club_id"], name: "index_routine_club_members_on_routine_club_id"
    t.index ["status"], name: "index_routine_club_members_on_status"
    t.index ["user_id", "status"], name: "index_routine_club_members_on_user_id_and_status"
    t.index ["user_id"], name: "index_routine_club_members_on_user_id"
  end

  create_table "routine_club_penalties", force: :cascade do |t|
    t.text "appeal_message"
    t.datetime "appealed_at"
    t.datetime "created_at", null: false
    t.integer "issued_by_id"
    t.integer "penalty_points", default: 1
    t.integer "penalty_type", default: 0, null: false
    t.text "reason"
    t.integer "routine_club_id", null: false
    t.integer "routine_club_member_id", null: false
    t.integer "routine_club_rule_id"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["issued_by_id"], name: "index_routine_club_penalties_on_issued_by_id"
    t.index ["routine_club_id"], name: "index_routine_club_penalties_on_routine_club_id"
    t.index ["routine_club_member_id"], name: "index_routine_club_penalties_on_routine_club_member_id"
    t.index ["routine_club_rule_id"], name: "index_routine_club_penalties_on_routine_club_rule_id"
    t.index ["status"], name: "index_routine_club_penalties_on_status"
  end

  create_table "routine_club_reports", force: :cascade do |t|
    t.integer "absence_count", default: 0
    t.float "achievement_rate"
    t.integer "attendance_count", default: 0
    t.float "attendance_rate", default: 0.0
    t.text "cheering_message"
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.string "identity_title"
    t.float "log_rate"
    t.integer "received_cheers_count", default: 0
    t.integer "report_type", default: 0, null: false
    t.integer "routine_club_id", null: false
    t.date "start_date", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["report_type", "start_date"], name: "index_routine_club_reports_on_report_type_and_start_date"
    t.index ["routine_club_id"], name: "index_routine_club_reports_on_routine_club_id"
    t.index ["start_date"], name: "index_routine_club_reports_on_start_date"
    t.index ["user_id", "report_type"], name: "index_routine_club_reports_on_user_id_and_report_type"
    t.index ["user_id", "routine_club_id", "report_type", "start_date"], name: "index_reports_on_user_club_type_date", unique: true
    t.index ["user_id"], name: "index_routine_club_reports_on_user_id"
  end

  create_table "routine_club_rules", force: :cascade do |t|
    t.boolean "auto_kick_enabled", default: false
    t.integer "auto_kick_threshold"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "has_penalty", default: false
    t.text "penalty_description"
    t.integer "penalty_points", default: 0
    t.integer "position", default: 0
    t.integer "routine_club_id", null: false
    t.integer "rule_type", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["routine_club_id", "position"], name: "index_routine_club_rules_on_routine_club_id_and_position"
    t.index ["routine_club_id"], name: "index_routine_club_rules_on_routine_club_id"
  end

  create_table "routine_clubs", force: :cascade do |t|
    t.string "account_holder", default: "루틴파인더스"
    t.string "account_number", default: "110-123-456789"
    t.integer "auto_kick_threshold", default: 10
    t.decimal "average_attendance_rate", precision: 5, scale: 2, default: "0.0"
    t.string "bank_name", default: "신한은행"
    t.string "category"
    t.float "completion_attendance_rate", default: 70.0
    t.datetime "created_at", null: false
    t.integer "current_members", default: 0
    t.text "description"
    t.date "end_date", null: false
    t.integer "golden_fire_bonus", default: 20
    t.integer "host_id", null: false
    t.boolean "is_official"
    t.boolean "lecture_room_active"
    t.text "lecture_room_description"
    t.string "lecture_room_title"
    t.boolean "live_room_active"
    t.string "live_room_button_text"
    t.string "live_room_title"
    t.integer "max_members", default: 30
    t.integer "min_duration_months", default: 3, null: false
    t.integer "monthly_fee", default: 0, null: false
    t.string "monthly_reward_info"
    t.integer "relax_pass_limit", default: 3
    t.integer "save_pass_limit", default: 3
    t.string "season_reward_info"
    t.string "special_lecture_link"
    t.date "start_date", null: false
    t.integer "status", default: 0, null: false
    t.string "thumbnail_image"
    t.string "title", null: false
    t.integer "total_penalties", default: 0
    t.datetime "updated_at", null: false
    t.string "weekly_reward_info"
    t.string "zoom_link"
    t.index ["category"], name: "index_routine_clubs_on_category"
    t.index ["host_id"], name: "index_routine_clubs_on_host_id"
    t.index ["status"], name: "index_routine_clubs_on_status"
  end

  create_table "routine_templates", force: :cascade do |t|
    t.string "author_name"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "days"
    t.text "description"
    t.string "icon"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "rufa_activities", force: :cascade do |t|
    t.string "activity_type"
    t.text "body"
    t.integer "claps_count", default: 0
    t.datetime "created_at", null: false
    t.integer "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_rufa_activities_on_user_id"
  end

  create_table "rufa_claps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "rufa_activity_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["rufa_activity_id"], name: "index_rufa_claps_on_rufa_activity_id"
    t.index ["user_id"], name: "index_rufa_claps_on_user_id"
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
    t.index ["granted_at"], name: "index_user_badges_on_granted_at"
    t.index ["user_id", "is_viewed"], name: "index_user_badges_on_user_id_and_is_viewed"
    t.index ["user_id"], name: "index_user_badges_on_user_id"
  end

  create_table "user_goals", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "goal_type"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_user_goals_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.decimal "avg_completion_rate", precision: 5, scale: 2, default: "0.0"
    t.text "bio"
    t.integer "completed_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", null: false
    t.decimal "host_avg_completion_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "host_completed_challenges", default: 0
    t.integer "host_total_participants", default: 0
    t.boolean "is_featured_host"
    t.integer "level", default: 1, null: false
    t.text "monthly_goal"
    t.datetime "monthly_goal_updated_at"
    t.string "nickname", null: false
    t.json "notification_preferences"
    t.boolean "onboarding_completed", default: false, null: false
    t.integer "ongoing_count", default: 0, null: false
    t.string "password_digest"
    t.string "phone_number"
    t.string "profile_image"
    t.string "provider"
    t.integer "role", default: 0, null: false
    t.string "saved_account_holder"
    t.string "saved_account_number"
    t.string "saved_bank_name"
    t.json "sns_links", default: {}
    t.datetime "suspended_at"
    t.datetime "threads_expires_at"
    t.string "threads_refresh_token"
    t.string "threads_token"
    t.integer "total_exp", default: 0, null: false
    t.integer "total_refunded", default: 0, null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.integer "wallet_balance", default: 0, null: false
    t.text "weekly_goal"
    t.datetime "weekly_goal_updated_at"
    t.text "yearly_goal"
    t.datetime "yearly_goal_updated_at"
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
    t.index ["created_at"], name: "index_verification_logs_on_created_at"
    t.index ["participant_id", "created_at"], name: "index_verification_logs_on_participant_id_and_created_at"
    t.index ["participant_id", "status"], name: "index_verification_logs_on_participant_id_and_status"
    t.index ["participant_id"], name: "index_verification_logs_on_participant_id"
    t.index ["status"], name: "index_verification_logs_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcements", "challenges"
  add_foreign_key "announcements", "routine_clubs"
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
  add_foreign_key "routine_club_attendances", "routine_club_members"
  add_foreign_key "routine_club_attendances", "routine_clubs"
  add_foreign_key "routine_club_gatherings", "routine_clubs"
  add_foreign_key "routine_club_members", "routine_clubs"
  add_foreign_key "routine_club_members", "users"
  add_foreign_key "routine_club_penalties", "routine_club_members"
  add_foreign_key "routine_club_penalties", "routine_club_rules"
  add_foreign_key "routine_club_penalties", "routine_clubs"
  add_foreign_key "routine_club_penalties", "users", column: "issued_by_id"
  add_foreign_key "routine_club_reports", "routine_clubs"
  add_foreign_key "routine_club_reports", "users"
  add_foreign_key "routine_club_rules", "routine_clubs"
  add_foreign_key "routine_clubs", "users", column: "host_id"
  add_foreign_key "rufa_activities", "users"
  add_foreign_key "rufa_claps", "rufa_activities"
  add_foreign_key "rufa_claps", "users"
  add_foreign_key "staffs", "challenges"
  add_foreign_key "staffs", "users"
  add_foreign_key "user_badges", "badges"
  add_foreign_key "user_badges", "users"
  add_foreign_key "user_goals", "users"
  add_foreign_key "verification_logs", "challenges"
  add_foreign_key "verification_logs", "participants"
end
