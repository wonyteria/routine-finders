class AddOriginalChallengeToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_reference :challenges, :original_challenge, null: true, foreign_key: { to_table: :challenges }
  end
end
