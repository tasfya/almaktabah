class AddSeriesToLessons < ActiveRecord::Migration[8.0]
  def change
    add_reference :lessons, :series, null: false, foreign_key: true
  end
end
