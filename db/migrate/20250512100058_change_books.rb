class ChangeBooks < ActiveRecord::Migration[8.0]
  def change
    change_table :books do |t|
      t.string :title, null: false
      t.text :description
      t.string :category
      t.date :published_date
      t.integer :views, default: 0
      t.integer :downloads, default: 0
      t.index :title
      t.index :category
    end
  end
end
