class AddTimeZoneToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :time_zone, :string, default: "Asia/Seoul", null: false
  end
end
