class AddMultipleVerificationMethodsToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :v_photo, :boolean
    add_column :challenges, :v_simple, :boolean
    add_column :challenges, :v_metric, :boolean
    add_column :challenges, :v_url, :boolean
  end
end
