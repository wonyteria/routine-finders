class RemoveClapsCountFromRufaActivities < ActiveRecord::Migration[8.1]
  def change
    remove_column :rufa_activities, :claps_count, :integer
  end
end
