class AddLinksToRoutineClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_clubs, :zoom_link, :string
    add_column :routine_clubs, :special_lecture_link, :string
  end
end
