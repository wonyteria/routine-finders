class AddRecruitmentDatesToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :recruitment_start_date, :date
    add_column :challenges, :recruitment_end_date, :date
  end
end
