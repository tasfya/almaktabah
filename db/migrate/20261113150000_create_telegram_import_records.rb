class CreateTelegramImportRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :telegram_import_records do |t|
      t.string :source, null: false
      t.string :external_id, null: false
      t.references :record, polymorphic: true, null: false
      t.string :outcome, null: false
      t.timestamps
    end
    add_index :telegram_import_records, [ :source, :external_id ], unique: true
  end
end
