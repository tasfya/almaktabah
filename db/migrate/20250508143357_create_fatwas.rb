class CreateFatwas < ActiveRecord::Migration[8.0]
  def change
    create_table :fatwas do |t|
      t.string :title
      t.string :category
      t.integer :views, default: 0
      t.date :published_date
      t.timestamps
    end
  end
end
