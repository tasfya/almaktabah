class EnforceScholarOnFatwasAndNews < ActiveRecord::Migration[8.0]
  def up
    null_fatwas = select_value("SELECT COUNT(*) FROM fatwas WHERE scholar_id IS NULL").to_i
    null_news = select_value("SELECT COUNT(*) FROM news WHERE scholar_id IS NULL").to_i
    if null_fatwas.positive? || null_news.positive?
      raise "Backfill scholar_id before enforcing NOT NULL (fatwas=#{null_fatwas}, news=#{null_news})"
    end

    remove_foreign_key :fatwas, :scholars if foreign_key_exists?(:fatwas, :scholars)
    add_foreign_key :fatwas, :scholars

    change_column_null :fatwas, :scholar_id, false
    change_column_null :news, :scholar_id, false
  end

  def down
    change_column_null :fatwas, :scholar_id, true
    change_column_null :news, :scholar_id, true

    remove_foreign_key :fatwas, :scholars if foreign_key_exists?(:fatwas, :scholars)
    add_foreign_key :fatwas, :scholars, on_delete: :nullify
  end
end
