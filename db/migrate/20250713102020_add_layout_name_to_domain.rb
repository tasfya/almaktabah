class AddLayoutNameToDomain < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :layout_name, :string, default: "application", null: false
  end
end
