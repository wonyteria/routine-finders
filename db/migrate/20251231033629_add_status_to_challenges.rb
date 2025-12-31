class AddStatusToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :status, :integer, default: 0, null: false
    add_index :challenges, :status
  end
end
