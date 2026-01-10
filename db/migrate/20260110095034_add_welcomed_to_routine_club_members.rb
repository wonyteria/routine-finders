class AddWelcomedToRoutineClubMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_club_members, :welcomed, :boolean, default: false
  end
end
