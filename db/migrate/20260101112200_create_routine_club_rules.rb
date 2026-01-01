# frozen_string_literal: true

class CreateRoutineClubRules < ActiveRecord::Migration[8.1]
  def change
    create_table :routine_club_rules do |t|
      t.references :routine_club, null: false, foreign_key: true

      # 규칙 내용
      t.string :title, null: false
      t.text :description
      t.integer :rule_type, default: 0, null: false # attendance: 0, behavior: 1, communication: 2, custom: 3

      # 패널티
      t.boolean :has_penalty, default: false
      t.text :penalty_description
      t.integer :penalty_points, default: 0

      # 자동 강퇴 조건
      t.boolean :auto_kick_enabled, default: false
      t.integer :auto_kick_threshold # 예: 3회 위반 시 자동 강퇴

      # 순서
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :routine_club_rules, [ :routine_club_id, :position ]
  end
end
