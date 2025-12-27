class AddExtendedFieldsToChallenges < ActiveRecord::Migration[8.1]
  def change
    add_column :challenges, :invitation_code, :string
    add_index :challenges, :invitation_code, unique: true
    add_column :challenges, :is_private, :boolean, default: false, null: false
    add_column :challenges, :meeting_link, :string
    add_column :challenges, :requires_application_message, :boolean, default: false, null: false
    add_column :challenges, :re_verification_allowed, :boolean, default: false, null: false
    add_column :challenges, :verification_start_time, :time
    add_column :challenges, :verification_end_time, :time
    add_column :challenges, :likes_count, :integer, default: 0, null: false
    add_column :challenges, :average_rating, :decimal, precision: 3, scale: 2, default: 0.0
  end
end
