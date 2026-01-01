# frozen_string_literal: true

class CreateRoutineClubMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :routine_club_members do |t|
      t.references :routine_club, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # 참여 정보
      t.datetime :joined_at, null: false
      t.date :membership_start_date, null: false
      t.date :membership_end_date, null: false
      t.integer :paid_amount, null: false, default: 0

      # 입금 확인
      t.integer :payment_status, default: 0, null: false # pending: 0, confirmed: 1, rejected: 2
      t.string :depositor_name
      t.datetime :deposit_confirmed_at

      # 상태
      t.integer :status, default: 0, null: false # active: 0, warned: 1, kicked: 2, left: 3
      t.text :kick_reason

      # 통계
      t.integer :attendance_count, default: 0
      t.integer :absence_count, default: 0
      t.integer :penalty_count, default: 0
      t.decimal :attendance_rate, precision: 5, scale: 2, default: 0.0

      # 역할
      t.boolean :is_moderator, default: false

      t.timestamps
    end

    add_index :routine_club_members, [ :routine_club_id, :user_id ], unique: true
    add_index :routine_club_members, :payment_status
    add_index :routine_club_members, :status
  end
end
