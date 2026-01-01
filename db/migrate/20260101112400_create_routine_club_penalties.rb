# frozen_string_literal: true

class CreateRoutineClubPenalties < ActiveRecord::Migration[8.1]
  def change
    create_table :routine_club_penalties do |t|
      t.references :routine_club, null: false, foreign_key: true
      t.references :routine_club_member, null: false, foreign_key: true
      t.references :routine_club_rule, foreign_key: true
      t.references :issued_by, foreign_key: { to_table: :users }

      # 패널티 정보
      t.string :title, null: false
      t.text :reason
      t.integer :penalty_points, default: 1
      t.integer :penalty_type, default: 0, null: false # warning: 0, point: 1, kick: 2

      # 상태
      t.integer :status, default: 0, null: false # active: 0, appealed: 1, revoked: 2
      t.text :appeal_message
      t.datetime :appealed_at

      t.timestamps
    end

    add_index :routine_club_penalties, :status
  end
end
