class CreateEnrollmentsAndLessonCompletions < ActiveRecord::Migration[8.1]
  def change
    create_table :enrollments do |t|
      t.references :learner, null: false, foreign_key: true, index: false
      t.references :cohort, null: false, foreign_key: true
      t.references :domain, null: false, foreign_key: true
      t.datetime :enrolled_at, null: false
      t.datetime :completed_at
      t.boolean :reminders_enabled, null: false, default: true
      t.timestamps
    end
    add_index :enrollments, [ :learner_id, :cohort_id ], unique: true

    create_table :lesson_completions do |t|
      t.references :enrollment, null: false, foreign_key: true, index: false
      t.references :program_item, null: false, foreign_key: true
      t.datetime :completed_at, null: false
      t.timestamps
    end
    add_index :lesson_completions, [ :enrollment_id, :program_item_id ], unique: true
  end
end
