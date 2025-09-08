class AddSlugToBenefits < ActiveRecord::Migration[8.0]
  def change
    add_column :benefits, :slug, :string
    add_index :benefits, :slug, unique: true
  end
end
