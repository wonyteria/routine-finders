class CreateRufaClaps < ActiveRecord::Migration[8.1]
  def change
    create_table :rufa_claps do |t|
      t.references :user, null: false, foreign_key: true
      t.references :rufa_activity, null: false, foreign_key: true

      t.timestamps
    end
  end
end
