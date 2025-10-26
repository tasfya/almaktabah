class CreateUserScholars < ActiveRecord::Migration[8.0]
  def change
    create_table :user_scholars do |t|
      t.references :user, null: false, foreign_key: true
      t.references :scholar, null: false, foreign_key: true

      t.timestamps
    end
  end
end
