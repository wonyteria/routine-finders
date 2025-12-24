class CreateVerificationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :verification_logs do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true
      t.integer :verification_type, default: 0, null: false
      t.string :value
      t.string :image_url
      t.json :reactions, default: []
      t.boolean :is_late, default: false, null: false
      t.integer :status, default: 0, null: false
      t.string :reject_reason

      t.timestamps
    end

    add_index :verification_logs, [:challenge_id, :created_at]
    add_index :verification_logs, :status
  end
end
