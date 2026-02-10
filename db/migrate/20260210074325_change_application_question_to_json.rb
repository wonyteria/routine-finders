class ChangeApplicationQuestionToJson < ActiveRecord::Migration[8.1]
  def up
    # Add new JSON column
    add_column :challenges, :application_questions, :json, default: []

    # Migrate existing data
    Challenge.reset_column_information
    Challenge.find_each do |challenge|
      if challenge.application_question.present?
        challenge.update_column(:application_questions, [ challenge.application_question ])
      end
    end

    # Remove old column
    remove_column :challenges, :application_question

    # Add new JSON column for challenge_applications to store answers
    add_column :challenge_applications, :application_answers, :json, default: {}

    # Migrate existing message data to new format
    ChallengeApplication.reset_column_information
    ChallengeApplication.find_each do |application|
      if application.message.present?
        # Store the old message as answer to the first question
        application.update_column(:application_answers, { "0" => application.message })
      end
    end
  end

  def down
    # Add back old column
    add_column :challenges, :application_question, :text

    # Migrate data back
    Challenge.reset_column_information
    Challenge.find_each do |challenge|
      if challenge.application_questions.present? && challenge.application_questions.any?
        challenge.update_column(:application_question, challenge.application_questions.first)
      end
    end

    # Remove new column
    remove_column :challenges, :application_questions

    # Remove answers column
    remove_column :challenge_applications, :application_answers
  end
end
