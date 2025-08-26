class DropBenefitsTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :benefits
  end

  def down
    create_table :benefits do |t|
      t.string :title, null: false
      t.text :content
      t.string :category
      t.references :scholar, null: true, foreign_key: true
      t.string :slug
      t.boolean :published, default: false
      t.datetime :published_at
      t.string :source_url
      t.references :domain, null: false, foreign_key: true

      t.timestamps
    end

    add_index :benefits, :published
    add_index :benefits, :scholar_id
    add_index :benefits, :slug, unique: true
  end
end
