class AddFinalAchievementToParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :participants, :final_achievement_rate, :decimal, precision: 5, scale: 2
    add_column :participants, :refund_amount, :integer, default: 0
  end
end
