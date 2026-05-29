class AddCategoryToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :category, :string
    add_index :articles, :category
  end
end
