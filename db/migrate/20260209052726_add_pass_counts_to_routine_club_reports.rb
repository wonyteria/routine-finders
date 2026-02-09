class AddPassCountsToRoutineClubReports < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_club_reports, :relax_pass_count, :integer
    add_column :routine_club_reports, :save_pass_count, :integer
    add_column :routine_club_reports, :unknown_pass_count, :integer
  end
end
