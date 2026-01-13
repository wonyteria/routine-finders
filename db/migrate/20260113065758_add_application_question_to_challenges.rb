class AddApplicationQuestionToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :application_question, :text
  end
end
