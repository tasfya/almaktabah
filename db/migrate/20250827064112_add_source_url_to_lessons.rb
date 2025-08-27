class AddSourceUrlToLessons < ActiveRecord::Migration[8.0]
  def change
    add_column :lessons, :source_url, :string
  end
end
