class AddThreadsNicknameToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :routine_club_members, :threads_nickname, :string
    add_column :participants, :threads_nickname, :string
  end
end
