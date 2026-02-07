class AddMessageToHostToReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :reviews, :message_to_host, :text
  end
end
