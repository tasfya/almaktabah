class AddSlugToNews < ActiveRecord::Migration[8.0]
  def change
    remove_column :news, :slug, :string if column_exists?(:news, :slug)
    add_column :news, :slug, :string
    add_index :news, :slug, unique: true
  end
end
