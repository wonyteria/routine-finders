class AddPassTypeToRoutineClubAttendances < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_club_attendances, :pass_type, :string
  end
end
