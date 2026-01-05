class AddRoutineClubToAnnouncements < ActiveRecord::Migration[8.1]
  def change
    add_reference :announcements, :routine_club, null: true, foreign_key: true
  end
end
