class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.string :title
      t.references :author, null: false, foreign_key: {to_table: :scholars}

      t.timestamps
    end
  end
end
