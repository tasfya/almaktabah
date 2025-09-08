class AddPublishedAtToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :published_at, :datetime
  end
end
