class AddSlugToFatwas < ActiveRecord::Migration[8.0]
  def change
    add_column :fatwas, :slug, :string
    add_index :fatwas, :slug, unique: true
  end
end
