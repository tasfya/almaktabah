class CreateScholars < ActiveRecord::Migration[8.0]
  def change
    create_table :scholars do |t|
      t.string :full_name
      t.text :bio
      t.date :dob

      t.timestamps
    end
  end
end
