class AddThreadsAuthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :threads_token, :string
    add_column :users, :threads_refresh_token, :string
    add_column :users, :threads_expires_at, :datetime
  end
end
