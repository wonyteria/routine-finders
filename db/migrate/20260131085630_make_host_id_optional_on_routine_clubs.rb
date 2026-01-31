class MakeHostIdOptionalOnRoutineClubs < ActiveRecord::Migration[7.1]
  def change
    change_column_null :routine_clubs, :host_id, true
  end
end
