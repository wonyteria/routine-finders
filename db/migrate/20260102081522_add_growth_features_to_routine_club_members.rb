class AddGrowthFeaturesToRoutineClubMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_club_members, :used_passes_count, :integer
    add_column :routine_club_members, :growth_points, :integer
  end
end
