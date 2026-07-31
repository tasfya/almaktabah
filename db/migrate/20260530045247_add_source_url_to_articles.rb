class AddSourceUrlToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :source_url, :string
    add_index :articles, :source_url
  end
end
