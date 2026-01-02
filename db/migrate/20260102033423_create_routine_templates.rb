class CreateRoutineTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :routine_templates do |t|
      t.string :title
      t.text :description
      t.string :category
      t.string :icon
      t.text :days
      t.string :author_name

      t.timestamps
    end
  end
end
