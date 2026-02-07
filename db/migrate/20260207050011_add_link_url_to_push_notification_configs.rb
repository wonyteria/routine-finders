class AddLinkUrlToPushNotificationConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :push_notification_configs, :link_url, :string
  end
end
