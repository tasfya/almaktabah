class AddSlugToNews < ActiveRecord::Migration[8.0]
  def change
    add_column :news, :slug, :string unless column_exists?(:news, :slug)
  end
end
