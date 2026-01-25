class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # Challenges 테이블 인덱스
    add_index :challenges, :recruitment_end_date, if_not_exists: true
    add_index :challenges, :end_date, if_not_exists: true
    add_index :challenges, :current_participants, if_not_exists: true
    add_index :challenges, [ :end_date, :created_at ], if_not_exists: true

    # Participants 테이블 인덱스
    add_index :participants, [ :challenge_id, :status ], if_not_exists: true
    add_index :participants, [ :user_id, :status ], if_not_exists: true
    add_index :participants, :completion_rate, if_not_exists: true

    # Personal Routines 테이블 인덱스
    add_index :personal_routines, [ :user_id, :created_at ], if_not_exists: true

    # Verification Logs 테이블 인덱스
    add_index :verification_logs, [ :participant_id, :created_at ], if_not_exists: true
    add_index :verification_logs, [ :participant_id, :status ], if_not_exists: true
    add_index :verification_logs, :created_at, if_not_exists: true

    # Routine Club Members 테이블 인덱스
    add_index :routine_club_members, [ :routine_club_id, :status ], if_not_exists: true
    add_index :routine_club_members, [ :user_id, :status ], if_not_exists: true
    add_index :routine_club_members, :attendance_rate, if_not_exists: true

    # Routine Club Reports 테이블 인덱스
    add_index :routine_club_reports, [ :user_id, :report_type ], if_not_exists: true
    add_index :routine_club_reports, [ :report_type, :start_date ], if_not_exists: true
    add_index :routine_club_reports, :start_date, if_not_exists: true

    # Notifications 테이블 인덱스
    add_index :notifications, [ :user_id, :is_read ], if_not_exists: true
    add_index :notifications, [ :user_id, :created_at ], if_not_exists: true

    # User Badges 테이블 인덱스
    add_index :user_badges, [ :user_id, :is_viewed ], if_not_exists: true
    add_index :user_badges, :granted_at, if_not_exists: true
  end
end
