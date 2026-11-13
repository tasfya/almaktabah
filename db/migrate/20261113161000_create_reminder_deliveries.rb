class CreateReminderDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :reminder_deliveries do |t|
      t.references :enrollment, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.date :local_date, null: false
      t.datetime :sent_at
      t.timestamps
    end
    add_index :reminder_deliveries, [ :enrollment_id, :local_date ], unique: true
  end
end
