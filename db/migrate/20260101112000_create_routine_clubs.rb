# frozen_string_literal: true

class CreateRoutineClubs < ActiveRecord::Migration[8.1]
  def change
    create_table :routine_clubs do |t|
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :category
      t.string :thumbnail_image

      # 기간 및 요금
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :monthly_fee, null: false, default: 0
      t.integer :min_duration_months, null: false, default: 3

      # 인원
      t.integer :max_members, default: 30
      t.integer :current_members, default: 0

      # 상태
      t.integer :status, default: 0, null: false # recruiting: 0, active: 1, ended: 2

      # 계좌 정보 (루틴 파인더스 계좌)
      t.string :bank_name, default: "신한은행"
      t.string :account_number, default: "110-123-456789"
      t.string :account_holder, default: "루틴파인더스"

      # 통계
      t.decimal :average_attendance_rate, precision: 5, scale: 2, default: 0.0
      t.integer :total_penalties, default: 0

      t.timestamps
    end

    add_index :routine_clubs, :status
    add_index :routine_clubs, :category
  end
end
