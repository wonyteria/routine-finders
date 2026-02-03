class DropRufaClaps < ActiveRecord::Migration[7.2]
  def change
    drop_table :rufa_claps do |t|
      t.integer :user_id, null: false
      t.integer :rufa_activity_id, null: false
      t.timestamps
    end
  end
end
