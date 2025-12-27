class CreateChallengeApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :challenge_applications do |t|
      t.references :challenge, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.text :message
      t.string :depositor_name
      t.text :reject_reason
      t.datetime :applied_at

      t.timestamps
    end
    add_index :challenge_applications, [ :challenge_id, :user_id ], unique: true
  end
end
