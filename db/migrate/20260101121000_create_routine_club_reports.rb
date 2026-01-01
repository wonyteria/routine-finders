# frozen_string_literal: true

class CreateRoutineClubReports < ActiveRecord::Migration[8.1]
  def change
    create_table :routine_club_reports do |t|
      t.references :routine_club, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :report_type, null: false, default: 0
      t.date :start_date, null: false
      t.date :end_date, null: false

      # 통계 데이터
      t.integer :attendance_count, default: 0
      t.integer :absence_count, default: 0
      t.integer :received_cheers_count, default: 0
      t.float :attendance_rate, default: 0.0

      # 리포트 내용
      t.text :summary
      t.text :cheering_message

      t.timestamps
    end

    add_index :routine_club_reports, [ :user_id, :routine_club_id, :report_type, :start_date ], unique: true, name: 'index_reports_on_user_club_type_date'
  end
end
