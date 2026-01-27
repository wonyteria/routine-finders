class RemoveEmailVerificationFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_index :users, :email_verification_token, if_exists: true
    remove_column :users, :email_verified, :boolean
    remove_column :users, :email_verification_token, :string
    remove_column :users, :email_verification_sent_at, :datetime
  end
end
