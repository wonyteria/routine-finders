class AddIdentityTitleToRoutineClubMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_club_members, :identity_title, :string
  end
end
