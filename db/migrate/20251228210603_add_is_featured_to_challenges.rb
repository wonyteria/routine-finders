class AddIsFeaturedToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :is_featured, :boolean
  end
end
