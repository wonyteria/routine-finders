# frozen_string_literal: true

class CreateRoutineClubAttendances < ActiveRecord::Migration[8.1]
  def change
    create_table :routine_club_attendances do |t|
      t.references :routine_club, null: false, foreign_key: true
      t.references :routine_club_member, null: false, foreign_key: true

      # 출석 정보
      t.date :attendance_date, null: false
      t.integer :status, default: 0, null: false # present: 0, absent: 1, excused: 2

      # 인증
      t.text :proof_text
      t.string :proof_image
      t.datetime :submitted_at

      # 응원/피드백
      t.integer :cheers_count, default: 0
      t.json :cheers_from_users, default: []

      t.timestamps
    end

    add_index :routine_club_attendances, [ :routine_club_member_id, :attendance_date ], unique: true, name: 'index_club_attendances_on_member_and_date'
    add_index :routine_club_attendances, :attendance_date
  end
end
