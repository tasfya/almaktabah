class AddSlugToScholars < ActiveRecord::Migration[8.0]
  def change
    add_column :scholars, :slug, :string if !column_exists?(:scholars, :slug)
    add_index :scholars, :slug, unique: true if !index_exists?(:scholars, :slug, unique: true)
  end
end
