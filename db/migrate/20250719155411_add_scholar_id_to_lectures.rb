class AddScholarIdToLectures < ActiveRecord::Migration[8.0]
  def change
    add_reference :lectures, :scholar, null: true, foreign_key: true
  end
end
