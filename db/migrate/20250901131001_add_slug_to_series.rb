class AddSlugToSeries < ActiveRecord::Migration[8.0]
  def change
    add_column :series, :slug, :string
    add_index :series, :slug, unique: true
  end
end
