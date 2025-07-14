class CreateDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :domains do |t|
      t.string :name
      t.string :host
      t.text :description
      t.boolean :active

      t.timestamps
    end
  end
end
