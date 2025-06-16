class AddOldIdToLecturesAndMakeTitleUnique < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :old_id, :integer
    add_index :lectures, :title, unique: true
    add_index :lectures, :old_id
  end
end
