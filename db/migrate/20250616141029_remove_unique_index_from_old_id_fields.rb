class RemoveUniqueIndexFromOldIdFields < ActiveRecord::Migration[8.0]
  def change
    remove_index :lectures, :old_id
    remove_index :lessons, :old_id

    add_index :lectures, :old_id
    add_index :lessons, :old_id
  end
end
