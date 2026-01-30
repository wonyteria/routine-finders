class AddRulesToRoutineClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :routine_clubs, :relax_pass_limit, :integer, default: 3
    add_column :routine_clubs, :save_pass_limit, :integer, default: 3
    add_column :routine_clubs, :golden_fire_bonus, :integer, default: 20
    add_column :routine_clubs, :auto_kick_threshold, :integer, default: 10
    add_column :routine_clubs, :completion_attendance_rate, :float, default: 70.0
  end
end
