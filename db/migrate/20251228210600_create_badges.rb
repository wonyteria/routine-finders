class CreateBadges < ActiveRecord::Migration[8.0]
  def change
    create_table :badges do |t|
      t.string :name
      t.text :description
      t.string :badge_type
      t.integer :level
      t.float :requirement_value
      t.string :icon_path

      t.timestamps
    end
  end
end
