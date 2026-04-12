class AddIsDefaultToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :is_default, :boolean, default: false, null: false
    add_index :domains, :is_default, unique: true, where: "is_default = true"
  end
end
