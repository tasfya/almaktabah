class CreateDomainAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :domain_assignments do |t|
      t.references :assignable, polymorphic: true, null: false
      t.references :domain, null: false, foreign_key: true

      t.timestamps
    end
  end
end
