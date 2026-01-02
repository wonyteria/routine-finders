class AddIsOfficialToRoutineClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_clubs, :is_official, :boolean
  end
end
