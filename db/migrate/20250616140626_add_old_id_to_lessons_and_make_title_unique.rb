class AddOldIdToLessonsAndMakeTitleUnique < ActiveRecord::Migration[8.0]
  def change
    add_column :lessons, :old_id, :integer
    add_index :lessons, :title, unique: true
    add_index :lessons, :old_id
  end
end
