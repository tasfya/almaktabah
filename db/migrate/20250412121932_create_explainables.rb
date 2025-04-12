class CreateExplainables < ActiveRecord::Migration[8.0]
  def change
    create_table :explainables do |t|
      t.references :author, null: false, foreign_key: {to_table: :scholars}
      t.references :explainer, null: false, foreign_key: {to_table: :scholars}

      t.timestamps
    end
  end
end
