class AddDefaultDomainToScholars < ActiveRecord::Migration[8.0]
  def change
    add_reference :scholars, :default_domain, foreign_key: { to_table: :domains }, index: true
  end
end
