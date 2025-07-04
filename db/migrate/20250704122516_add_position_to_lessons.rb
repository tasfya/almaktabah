class AddPositionToLessons < ActiveRecord::Migration[8.0]
  def change
    add_column :lessons, :position, :integer
    add_index :lessons, :position
  end
end
