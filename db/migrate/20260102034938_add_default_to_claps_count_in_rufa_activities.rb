class AddDefaultToClapsCountInRufaActivities < ActiveRecord::Migration[8.1]
  def up
    change_column_default :rufa_activities, :claps_count, 0
    RufaActivity.where(claps_count: nil).update_all(claps_count: 0)
  end

  def down
    change_column_default :rufa_activities, :claps_count, nil
  end
end
