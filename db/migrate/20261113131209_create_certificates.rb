class CreateCertificates < ActiveRecord::Migration[8.1]
  def change
    create_table :certificates do |t|
      t.references :enrollment, foreign_key: { on_delete: :nullify }, index: { unique: true }
      t.references :domain, null: false, foreign_key: true
      t.string :number, null: false
      t.datetime :issued_at, null: false
      t.string :full_name_snapshot, null: false
      t.string :gender_snapshot, null: false
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :certificates, :number, unique: true
  end
end
