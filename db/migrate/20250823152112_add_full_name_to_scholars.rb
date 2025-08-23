class AddFullNameToScholars < ActiveRecord::Migration[8.0]
  def change
    add_column :scholars, :full_name, :string
    add_column :scholars, :full_name_alias, :string
  end
end
