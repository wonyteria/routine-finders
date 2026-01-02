class CreateBanners < ActiveRecord::Migration[8.1]
  def change
    create_table :banners do |t|
      t.string :title
      t.string :subtitle
      t.string :badge_text
      t.string :link_url
      t.integer :banner_type
      t.boolean :active
      t.integer :priority

      t.timestamps
    end
  end
end
