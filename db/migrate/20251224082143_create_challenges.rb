class CreateChallenges < ActiveRecord::Migration[8.1]
  def change
    create_table :challenges do |t|
      t.string :title, null: false
      t.string :thumbnail
      t.text :summary
      t.text :description
      t.string :purpose
      t.references :host, null: false, foreign_key: { to_table: :users }
      t.string :host_name
      t.string :host_account
      t.string :kakao_link
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.json :days, default: []
      t.integer :entry_type, default: 0, null: false
      t.integer :admission_type, default: 0, null: false
      t.integer :verification_type, default: 0, null: false
      t.integer :mode, default: 0, null: false
      t.integer :cost_type, default: 0, null: false
      t.integer :amount, default: 0, null: false
      t.integer :max_participants, default: 100, null: false
      t.integer :current_participants, default: 0, null: false
      t.decimal :completion_rate, precision: 5, scale: 2, default: 0.0
      t.string :category
      t.boolean :is_official, default: false, null: false
      t.integer :failure_tolerance, default: 3
      t.integer :penalty_per_failure, default: 0
      t.string :refund_timing
      t.integer :mission_frequency, default: 0, null: false
      t.integer :mission_weekly_count
      t.integer :mission_late_threshold
      t.boolean :mission_is_late_detection_enabled, default: false
      t.boolean :mission_allow_exceptions, default: false
      t.boolean :mission_is_consecutive, default: false
      t.boolean :mission_requires_host_approval, default: false

      t.timestamps
    end

    add_index :challenges, :mode
    add_index :challenges, :category
    add_index :challenges, :is_official
  end
end
