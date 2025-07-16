class DropContactsTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :contacts, if_exists: true do |t|
      t.string "name"
      t.string "email"
      t.string "subject"
      t.text "message"
      t.datetime "published_at"
      t.timestamps
    end
  end
end
