class CreateActionLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :action_logs do |t|
      t.string :action
      t.references :actionable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
