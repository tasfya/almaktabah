class AddScholarToBenefits < ActiveRecord::Migration[8.0]
  def change
    add_reference :benefits, :scholar, null: true, foreign_key: true
  end
end
