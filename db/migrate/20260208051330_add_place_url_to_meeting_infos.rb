class AddPlaceUrlToMeetingInfos < ActiveRecord::Migration[8.1]
  def change
    add_column :meeting_infos, :place_url, :string
  end
end
