class AddRefundDateToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :refund_date, :date
  end
end
