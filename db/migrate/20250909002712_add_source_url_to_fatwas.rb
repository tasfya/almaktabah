class AddSourceUrlToFatwas < ActiveRecord::Migration[8.0]
  def change
    add_column :fatwas, :source_url, :string
  end
end
