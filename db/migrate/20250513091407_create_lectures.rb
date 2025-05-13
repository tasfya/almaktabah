class CreateLectures < ActiveRecord::Migration[8.0]
  def change
    create_table :lectures do |t|
      t.string :title
      t.text :description
      t.integer :duration
      t.string :category
      t.integer :views
      t.date :published_date

      t.timestamps
    end
  end
end
