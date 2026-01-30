class AddHostPhoneToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :host_phone, :string
  end
end
