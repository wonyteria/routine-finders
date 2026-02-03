class CreatePushNotificationConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :push_notification_configs do |t|
      t.string :config_type, null: false
      t.string :title, null: false
      t.text :content, null: false
      t.string :schedule_time, default: "09:00"
      t.boolean :enabled, default: true

      t.timestamps
    end
    add_index :push_notification_configs, :config_type, unique: true
  end
end
