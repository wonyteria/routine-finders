class ChangeAnnouncementsForeignKeyConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :announcements, :challenge_id, true
    change_column_null :announcements, :routine_club_id, true
  end
end
