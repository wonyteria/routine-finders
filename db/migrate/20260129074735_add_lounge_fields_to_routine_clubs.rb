class AddLoungeFieldsToRoutineClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_clubs, :live_room_title, :string
    add_column :routine_clubs, :live_room_button_text, :string
    add_column :routine_clubs, :lecture_room_title, :string
    add_column :routine_clubs, :lecture_room_description, :text
  end
end
