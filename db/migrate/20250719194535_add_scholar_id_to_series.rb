class AddScholarIdToSeries < ActiveRecord::Migration[8.0]
  def change
    add_reference :series, :scholar, null: true, foreign_key: true
  end
end
