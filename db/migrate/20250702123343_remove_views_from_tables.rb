class RemoveViewsFromTables < ActiveRecord::Migration[8.0]
  def change
    remove_column :benefits, :views, :integer if column_exists?(:benefits, :views)
    remove_column :books, :views, :integer if column_exists?(:books, :views)
    remove_column :fatwas, :views, :integer if column_exists?(:fatwas, :views)
    remove_column :lectures, :views, :integer if column_exists?(:lectures, :views)
    remove_column :lessons, :view_count, :integer if column_exists?(:lessons, :view_count)
  end
end
