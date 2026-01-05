class CreateRoutineClubGatherings < ActiveRecord::Migration[8.1]
  def change
    create_table :routine_club_gatherings do |t|
      t.references :routine_club, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.datetime :gathering_at
      t.integer :gathering_type
      t.string :location
      t.integer :max_attendees

      t.timestamps
    end
  end
end
