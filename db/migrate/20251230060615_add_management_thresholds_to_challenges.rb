class AddManagementThresholdsToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :active_rate_threshold, :integer, default: 80
    add_column :challenges, :sluggish_rate_threshold, :integer, default: 50
    add_column :challenges, :non_participating_failures_threshold, :integer, default: 3
  end
end
