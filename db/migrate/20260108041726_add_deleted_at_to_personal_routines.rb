class AddDeletedAtToPersonalRoutines < ActiveRecord::Migration[8.1]
  def change
    add_column :personal_routines, :deleted_at, :datetime
  end
end
