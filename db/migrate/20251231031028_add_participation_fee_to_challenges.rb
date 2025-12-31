class AddParticipationFeeToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :participation_fee, :integer
  end
end
