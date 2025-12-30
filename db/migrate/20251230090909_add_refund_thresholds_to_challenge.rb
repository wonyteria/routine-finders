class AddRefundThresholdsToChallenge < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :full_refund_threshold, :decimal, precision: 5, scale: 2, default: 0.8
    add_column :challenges, :bonus_threshold, :decimal, precision: 5, scale: 2, default: 1.0
  end
end
