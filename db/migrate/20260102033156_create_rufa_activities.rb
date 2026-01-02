class CreateRufaActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :rufa_activities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :activity_type
      t.integer :target_id
      t.string :target_type
      t.text :body
      t.integer :claps_count

      t.timestamps
    end
  end
end
