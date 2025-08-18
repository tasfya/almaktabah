class AddSourceUrlToLectures < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :source_url, :string, null: true
  end
end
