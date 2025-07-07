class RemoveUniqueConstraintFromTitles < ActiveRecord::Migration[8.0]
  def change
    # Remove unique constraint from lessons table title
    remove_index :lessons, :title
    add_index :lessons, :title

    # Remove unique constraint from lectures table title
    remove_index :lectures, :title
    add_index :lectures, :title
  end
end
