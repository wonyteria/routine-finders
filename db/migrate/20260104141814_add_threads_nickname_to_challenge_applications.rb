class AddThreadsNicknameToChallengeApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :challenge_applications, :threads_nickname, :string
  end
end
