class CreateNews < ActiveRecord::Migration[8.0]
  def change
    create_table :news do |t|
      t.string :title
      t.text :content
      t.text :description
      t.datetime :published_at
      t.string :slug, null: false
      t.timestamps
    end

    add_index :news, :slug, unique: true
  end
end
