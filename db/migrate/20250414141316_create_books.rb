class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.references :author, null: false, foreign_key: { to_table: :scholars }

      t.timestamps
    end
  end
end
