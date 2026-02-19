class AddShareCountToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :share_count, :integer, default: 0
  end
end
