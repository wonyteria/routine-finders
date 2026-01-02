class CreateUserGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :user_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :goal_type
      t.text :body

      t.timestamps
    end
  end
end
