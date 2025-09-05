class AddSlugToScholars < ActiveRecord::Migration[8.0]
  def change
    add_column :scholars, :slug, :string
    add_index :scholars, :slug, unique: true
  end
end
