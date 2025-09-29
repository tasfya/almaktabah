class DropBenefitsTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :benefits
  end
end
