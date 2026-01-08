class ChangeDefaultOfUsedPassesCountToRoutineClubMembers < ActiveRecord::Migration[7.1]
  def change
    change_column_default :routine_club_members, :used_passes_count, 0
    # Update existing nils to 0
    RoutineClubMember.where(used_passes_count: nil).update_all(used_passes_count: 0)
  end
end
