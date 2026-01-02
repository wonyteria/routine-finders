class AddRufaFieldsToRoutineClubReports < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_club_reports, :log_rate, :float
    add_column :routine_club_reports, :achievement_rate, :float
    add_column :routine_club_reports, :identity_title, :string
  end
end
