class AddMissionGoalsToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :certification_goal, :text
    add_column :challenges, :daily_goals, :json
  end
end
