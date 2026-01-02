class AddContactInfoToApplicationsAndMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :challenge_applications, :contact_info, :string
    add_column :routine_club_members, :contact_info, :string
    add_column :participants, :contact_info, :string
  end
end
