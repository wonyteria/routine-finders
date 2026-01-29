class AddActiveStatusToRoutineClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_clubs, :live_room_active, :boolean
    add_column :routine_clubs, :lecture_room_active, :boolean
  end
end
