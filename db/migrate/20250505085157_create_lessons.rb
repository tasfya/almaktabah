class CreateLessons < ActiveRecord::Migration[8.0]
  def change
    create_table :lessons do |t|
      t.string :title
      t.date :published_date
      t.string :category
      t.integer :duration
      t.text :description
      t.timestamps
    end
  end
end
