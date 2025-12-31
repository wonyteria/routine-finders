class AddEditCountToReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :reviews, :edit_count, :integer, default: 0
  end
end
