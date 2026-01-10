class AddCommitmentToRoutineClubMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_club_members, :commitment, :text
  end
end
