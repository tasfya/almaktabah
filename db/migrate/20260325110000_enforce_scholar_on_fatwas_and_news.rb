class EnforceScholarOnFatwasAndNews < ActiveRecord::Migration[8.0]
  def up
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
