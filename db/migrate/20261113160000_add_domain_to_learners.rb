class AddDomainToLearners < ActiveRecord::Migration[8.1]
  def change
    add_reference :learners, :domain, null: true, foreign_key: { on_delete: :nullify }
  end
end
