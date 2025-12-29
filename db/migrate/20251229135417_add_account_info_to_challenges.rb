class AddAccountInfoToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :host_bank, :string
    add_column :challenges, :host_account_holder, :string
  end
end
