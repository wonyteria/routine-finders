class AddTargetTypeToBadges < ActiveRecord::Migration[8.1]
  def change
    add_column :badges, :target_type, :string
  end
end
