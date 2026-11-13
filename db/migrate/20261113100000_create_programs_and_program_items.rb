class CreateProgramsAndProgramItems < ActiveRecord::Migration[8.1]
  def change
    create_table :programs do |t|
      t.string :title, null: false
      t.string :slug
      t.text :description
      t.boolean :published, null: false, default: false
      t.datetime :published_at
      t.integer :pass_mark, null: false, default: 60
      t.timestamps
    end
    add_index :programs, :slug, unique: true

    create_table :program_items do |t|
      t.references :program, null: false, foreign_key: true
      t.integer :position, null: false
      t.integer :kind, null: false
      t.references :lesson, foreign_key: true
      t.references :book, foreign_key: true
      t.references :exam
      t.string :title_override
      t.boolean :hidden, null: false, default: false
      t.timestamps
      t.check_constraint "(CASE WHEN lesson_id IS NULL THEN 0 ELSE 1 END + CASE WHEN book_id IS NULL THEN 0 ELSE 1 END + CASE WHEN exam_id IS NULL THEN 0 ELSE 1 END) = 1",
        name: "program_items_exactly_one_reference"
    end
    add_index :program_items, [ :program_id, :position ], unique: true
  end
end
