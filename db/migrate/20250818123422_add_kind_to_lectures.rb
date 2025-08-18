class AddKindToLectures < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :kind, :integer, null: true
    add_index :lectures, :kind
  end
end
