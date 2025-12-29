# frozen_string_literal: true

class AddIsFeaturedHostToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :is_featured_host, :boolean
  end
end
