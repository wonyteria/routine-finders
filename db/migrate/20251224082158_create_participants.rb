class CreateParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :participants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true
      t.string :nickname
      t.string :profile_image
      t.boolean :today_verified, default: false, null: false
      t.decimal :completion_rate, precision: 5, scale: 2, default: 0.0
      t.integer :current_streak, default: 0, null: false
      t.integer :max_streak, default: 0, null: false
      t.integer :consecutive_failures, default: 0, null: false
      t.integer :total_failures, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.datetime :joined_at, null: false
      t.integer :paid_amount, default: 0, null: false

      t.timestamps
    end

    add_index :participants, [:user_id, :challenge_id], unique: true
    add_index :participants, :status
  end
end
