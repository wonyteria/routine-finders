class AddRefundFieldsToParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :participants, :refund_account_name, :string
    add_column :participants, :refund_bank_name, :string
    add_column :participants, :refund_account_number, :string
    add_column :participants, :refund_status, :integer
    add_column :participants, :refund_applied_at, :datetime
  end
end
