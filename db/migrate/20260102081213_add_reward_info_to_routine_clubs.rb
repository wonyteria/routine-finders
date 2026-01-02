class AddRewardInfoToRoutineClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_clubs, :weekly_reward_info, :string
    add_column :routine_clubs, :monthly_reward_info, :string
    add_column :routine_clubs, :season_reward_info, :string
  end
end
