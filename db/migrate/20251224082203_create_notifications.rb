class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :notification_type, default: 0, null: false
      t.string :title, null: false
      t.text :content
      t.boolean :is_read, default: false, null: false
      t.string :link

      t.timestamps
    end

    add_index :notifications, [:user_id, :is_read]
    add_index :notifications, [:user_id, :created_at]
  end
end
