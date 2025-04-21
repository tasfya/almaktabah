class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.string :subdomain
      t.string :name

      t.timestamps
    end
    add_index :tenants, :subdomain, unique: true
  end
end
