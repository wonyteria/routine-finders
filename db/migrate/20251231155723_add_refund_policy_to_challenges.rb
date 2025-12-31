class AddRefundPolicyToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :refund_policy, :text
  end
end
