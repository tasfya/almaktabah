class RemoveCategoryFromLessons < ActiveRecord::Migration[8.0]
  def change
    remove_column :lessons, :category, :string
  end
end
