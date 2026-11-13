class CreateCohortsAndCohortSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :cohorts do |t|
      t.references :program, null: false, foreign_key: true
      t.string :name, null: false
      t.date :starts_on, null: false
      t.string :time_zone, null: false, default: "Asia/Riyadh"
      t.datetime :enrollment_closes_at
      t.timestamps
    end

    create_table :cohort_slots do |t|
      t.references :cohort, null: false, foreign_key: true, index: false
      t.references :program_item, null: false, foreign_key: true
      t.date :available_on, null: false
      t.datetime :opens_at
      t.datetime :closes_at
      t.timestamps
    end
    add_index :cohort_slots, [ :cohort_id, :program_item_id ], unique: true
    add_index :cohort_slots, [ :cohort_id, :available_on ]
  end
end
