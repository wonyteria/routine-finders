class AddPassRefillToRoutineClubMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_club_members, :last_pass_refill_at, :datetime
  end
end
