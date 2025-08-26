class RemoveLayoutNameFromDomainsAddTemplateName < ActiveRecord::Migration[8.0]
  def change
    remove_column :domains, :layout_name, :string
    add_column :domains, :template_name, :string, default: "default", null: false
  end
end
