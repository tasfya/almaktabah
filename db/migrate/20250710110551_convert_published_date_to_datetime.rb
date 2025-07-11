class ConvertPublishedDateToDatetime < ActiveRecord::Migration[8.0]
  def up
    rename_column :articles, :published_date, :published_at if column_exists?(:articles, :published_date)
    rename_column :benefits, :published_date, :published_at if column_exists?(:benefits, :published_date)
    rename_column :books, :published_date, :published_at if column_exists?(:books, :published_date)
    rename_column :fatwas, :published_date, :published_at if column_exists?(:fatwas, :published_date)
    rename_column :lectures, :published_date, :published_at if column_exists?(:lectures, :published_date)
    rename_column :lessons, :published_date, :published_at if column_exists?(:lessons, :published_date)
    rename_column :series, :published_date, :published_at if column_exists?(:series, :published_date)

    change_column :articles, :published_at, :datetime if column_exists?(:articles, :published_at)
    change_column :benefits, :published_at, :datetime if column_exists?(:benefits, :published_at)
    change_column :books, :published_at, :datetime if column_exists?(:books, :published_at)
    change_column :fatwas, :published_at, :datetime if column_exists?(:fatwas, :published_at)
    change_column :lectures, :published_at, :datetime if column_exists?(:lectures, :published_at)
    change_column :lessons, :published_at, :datetime if column_exists?(:lessons, :published_at)
    change_column :series, :published_at, :datetime if column_exists?(:series, :published_at)

    add_column :scholars, :published_at, :datetime unless column_exists?(:scholars, :published_at)
    add_column :contacts, :published_at, :datetime unless column_exists?(:contacts, :published_at)
  end

  def down
    change_column :articles, :published_at, :date if column_exists?(:articles, :published_at)
    change_column :benefits, :published_at, :date if column_exists?(:benefits, :published_at)
    change_column :books, :published_at, :date if column_exists?(:books, :published_at)
    change_column :fatwas, :published_at, :date if column_exists?(:fatwas, :published_at)
    change_column :lectures, :published_at, :date if column_exists?(:lectures, :published_at)
    change_column :lessons, :published_at, :date if column_exists?(:lessons, :published_at)
    change_column :series, :published_at, :date if column_exists?(:series, :published_at)

    rename_column :articles, :published_at, :published_date if column_exists?(:articles, :published_at)
    rename_column :benefits, :published_at, :published_date if column_exists?(:benefits, :published_at)
    rename_column :books, :published_at, :published_date if column_exists?(:books, :published_at)
    rename_column :fatwas, :published_at, :published_date if column_exists?(:fatwas, :published_at)
    rename_column :lectures, :published_at, :published_date if column_exists?(:lectures, :published_at)
    rename_column :lessons, :published_at, :published_date if column_exists?(:lessons, :published_at)
    rename_column :series, :published_at, :published_date if column_exists?(:series, :published_at)

    remove_column :scholars, :published_at if column_exists?(:scholars, :published_at)
    remove_column :contacts, :published_at if column_exists?(:contacts, :published_at)
  end
end
