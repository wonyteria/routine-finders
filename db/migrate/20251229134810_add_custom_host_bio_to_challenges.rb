class AddCustomHostBioToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :custom_host_bio, :text
  end
end
