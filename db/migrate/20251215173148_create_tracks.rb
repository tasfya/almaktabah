class CreateTracks < ActiveRecord::Migration[8.0]
  def change
    create_table :tracks do |t|
      t.string :title
      t.text :description
      t.integer :difficulty_level
      t.integer :estimated_hours
      t.integer :position
      t.boolean :published
      t.string :slug
      t.integer :category

      t.timestamps
    end
  end
end
