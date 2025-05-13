class CreateBenefits < ActiveRecord::Migration[8.0]
  def change
    create_table :benefits do |t|
      t.string :title
      t.text :description
      t.string :category
      t.integer :views, default: 0
      t.integer :duration, default: 0
      t.date :published_date
      t.timestamps
    end
  end
end
