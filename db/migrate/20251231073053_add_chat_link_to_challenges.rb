class AddChatLinkToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :chat_link, :string
  end
end
