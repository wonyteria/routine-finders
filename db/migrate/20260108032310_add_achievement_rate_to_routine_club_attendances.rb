class AddAchievementRateToRoutineClubAttendances < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_club_attendances, :achievement_rate, :float
  end
end
