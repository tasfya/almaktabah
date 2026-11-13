class CreateExamAttemptsAndAttemptAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :exam_attempts do |t|
      t.references :enrollment, null: false, foreign_key: true, index: false
      t.references :exam, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :submitted_at
      t.integer :score_percent
      t.timestamps
    end
    add_index :exam_attempts, [ :enrollment_id, :exam_id ], unique: true

    create_table :attempt_answers do |t|
      t.references :exam_attempt, null: false, foreign_key: true, index: false
      t.references :question, null: false, foreign_key: true
      t.references :choice, null: false, foreign_key: true
      t.timestamps
    end
    add_index :attempt_answers, [ :exam_attempt_id, :question_id ], unique: true
  end
end
