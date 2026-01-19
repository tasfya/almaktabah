class AddTitleToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :title, :string
  end
end
