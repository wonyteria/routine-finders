class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements do |t|
      t.references :challenge, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content

      t.timestamps
    end
  end
end
