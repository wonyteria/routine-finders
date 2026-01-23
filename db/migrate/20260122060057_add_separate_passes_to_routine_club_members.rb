class AddSeparatePassesToRoutineClubMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_club_members, :used_relax_passes_count, :integer, default: 0
    add_column :routine_club_members, :used_save_passes_count, :integer, default: 0
  end
end
