class AddCustomCssToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :custom_css, :text
  end
end
