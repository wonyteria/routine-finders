# frozen_string_literal: true

class CreateUserBadges < ActiveRecord::Migration[8.1]
  def change
    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.references :badge, null: false, foreign_key: true
      t.datetime :granted_at
      t.boolean :is_viewed, default: false

      t.timestamps
    end
  end
end
