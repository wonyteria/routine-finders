class CreatePersonalRoutines < ActiveRecord::Migration[8.1]
  def change
    create_table :personal_routines do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :icon, default: "✨"
      t.json :days, default: []
      t.string :color, default: "bg-indigo-500"
      t.string :category
      t.integer :current_streak, default: 0, null: false
      t.integer :total_completions, default: 0, null: false
      t.date :last_completed_date

      t.timestamps
    end

    add_index :personal_routines, [:user_id, :title]
  end
end
