class CreateSolidCacheEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :solid_cache_entries, if_not_exists: true do |t|
      t.binary   :key,        null: false,   limit: 1024
      t.binary   :value,      null: false,   limit: 536870912
      t.datetime :created_at, null: false,   index: true
    end

    add_index :solid_cache_entries, :key, unique: true
  end
end
