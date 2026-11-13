class CreateExamsQuestionsChoices < ActiveRecord::Migration[8.1]
  def change
    create_table :exams do |t|
      t.references :program, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.timestamps
    end

    create_table :questions do |t|
      t.references :exam, null: false, foreign_key: true
      t.integer :position, null: false
      t.text :body, null: false
      t.integer :kind, null: false, default: 0
      t.timestamps
    end
    add_index :questions, [ :exam_id, :position ], unique: true

    create_table :choices do |t|
      t.references :question, null: false, foreign_key: true
      t.integer :position, null: false
      t.text :body, null: false
      t.boolean :correct, null: false, default: false
      t.timestamps
    end
    add_index :choices, [ :question_id, :position ], unique: true

    add_foreign_key :program_items, :exams
  end
end
