class AddRefundAccountToChallengeApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :challenge_applications, :refund_bank_name, :string
    add_column :challenge_applications, :refund_account_number, :string
    add_column :challenge_applications, :refund_account_name, :string
  end
end
