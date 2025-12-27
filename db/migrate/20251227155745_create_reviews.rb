class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :challenge, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :content
      t.integer :likes_count, default: 0, null: false

      t.timestamps
    end
    add_index :reviews, [ :challenge_id, :user_id ], unique: true
  end
end
