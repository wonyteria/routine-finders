class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :bio, :text
    add_column :users, :sns_links, :json, default: {}
    add_column :users, :saved_bank_name, :string
    add_column :users, :saved_account_number, :string
    add_column :users, :saved_account_holder, :string
  end
end
