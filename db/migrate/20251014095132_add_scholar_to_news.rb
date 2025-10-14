class AddScholarToNews < ActiveRecord::Migration[8.0]
  def change
    add_reference :news, :scholar, foreign_key: true, index: true
  end
end
