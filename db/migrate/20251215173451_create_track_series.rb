class CreateTrackSeries < ActiveRecord::Migration[8.0]
  def change
    create_table :track_series do |t|
      t.references :track, null: false, foreign_key: true
      t.references :series, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end
  end
end
