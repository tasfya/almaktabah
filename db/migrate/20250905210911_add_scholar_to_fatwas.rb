class AddScholarToFatwas < ActiveRecord::Migration[8.0]
  def change
    add_reference :fatwas, :scholar, null: true, foreign_key: { on_delete: :nullify }, index: true
  end
end
