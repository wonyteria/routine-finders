class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :nickname, null: false
      t.string :email, null: false
      t.string :profile_image
      t.integer :role, default: 0, null: false
      t.integer :level, default: 1, null: false
      t.integer :total_exp, default: 0, null: false
      t.integer :wallet_balance, default: 0, null: false
      t.integer :total_refunded, default: 0, null: false
      t.integer :ongoing_count, default: 0, null: false
      t.integer :completed_count, default: 0, null: false
      t.decimal :avg_completion_rate, precision: 5, scale: 2, default: 0.0
      t.integer :host_total_participants, default: 0
      t.decimal :host_avg_completion_rate, precision: 5, scale: 2, default: 0.0
      t.integer :host_completed_challenges, default: 0

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :nickname
  end
end
