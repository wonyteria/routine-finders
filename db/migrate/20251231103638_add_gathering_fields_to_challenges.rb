class AddGatheringFieldsToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :meeting_type, :integer
    add_column :challenges, :meeting_frequency, :string
    add_column :challenges, :duration_minutes, :integer
    add_column :challenges, :preparation_items, :text
    add_column :challenges, :min_participants, :integer
    add_column :challenges, :online_meeting_link, :string
  end
end
