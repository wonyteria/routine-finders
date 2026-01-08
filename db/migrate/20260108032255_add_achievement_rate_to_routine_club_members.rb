class AddAchievementRateToRoutineClubMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_club_members, :achievement_rate, :float
  end
end
