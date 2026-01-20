class AddGoalsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :weekly_goal, :text
    add_column :users, :monthly_goal, :text
    add_column :users, :yearly_goal, :text
    add_column :users, :weekly_goal_updated_at, :datetime
    add_column :users, :monthly_goal_updated_at, :datetime
    add_column :users, :yearly_goal_updated_at, :datetime
  end
end
