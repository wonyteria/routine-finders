class CreatePersonalRoutineCompletions < ActiveRecord::Migration[8.1]
  def change
    create_table :personal_routine_completions do |t|
      t.references :personal_routine, null: false, foreign_key: true
      t.date :completed_on

      t.timestamps
    end
    add_index :personal_routine_completions, :completed_on
  end
end
