class AddPublishedToAllResources < ActiveRecord::Migration[8.0]
  def up
    add_column :articles,  :published, :boolean, default: false, null: false
    add_column :benefits,  :published, :boolean, default: false, null: false
    add_column :books,     :published, :boolean, default: false, null: false
    add_column :fatwas,    :published, :boolean, default: false, null: false
    add_column :lectures,  :published, :boolean, default: false, null: false
    add_column :lessons,   :published, :boolean, default: false, null: false
    add_column :news,      :published, :boolean, default: false, null: false
    add_column :series,    :published, :boolean, default: false, null: false
    add_column :scholars,  :published, :boolean, default: false, null: false

    add_index :articles,  :published
    add_index :benefits,  :published
    add_index :books,     :published
    add_index :fatwas,    :published
    add_index :lectures,  :published
    add_index :lessons,   :published
    add_index :news,      :published
    add_index :series,    :published
    add_index :scholars,  :published
  end

  def down
    remove_index :articles,  :published
    remove_index :benefits,  :published
    remove_index :books,     :published
    remove_index :fatwas,    :published
    remove_index :lectures,  :published
    remove_index :lessons,   :published
    remove_index :news,      :published
    remove_index :series,    :published
    remove_index :scholars,  :published

    remove_column :articles,  :published
    remove_column :benefits,  :published
    remove_column :books,     :published
    remove_column :fatwas,    :published
    remove_column :lectures,  :published
    remove_column :lessons,   :published
    remove_column :news,      :published
    remove_column :series,    :published
    remove_column :scholars,  :published
  end
end
