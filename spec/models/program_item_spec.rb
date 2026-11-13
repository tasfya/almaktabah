require "rails_helper"

RSpec.describe ProgramItem, type: :model do
  it "requires exactly the reference matching its kind" do
    lesson_item = build(:program_item, :lesson)
    expect(lesson_item).to be_valid

    lesson_item.book = create(:book)
    expect(lesson_item).not_to be_valid
    expect(lesson_item.errors).to be_of_kind(:book_id, :present)

    expect(build(:program_item, kind: :lesson, lesson: nil)).not_to be_valid
    expect(build(:program_item, :book, kind: :lesson)).not_to be_valid
  end

  it "rejects two references at the DB level" do
    item = create(:program_item, :lesson)
    expect { item.update_columns(book_id: create(:book).id) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "rejects a missing reference at the DB level" do
    item = create(:program_item, :lesson)
    expect { item.update_columns(lesson_id: nil) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "keeps positions unique within a program" do
    item = create(:program_item)
    duplicate = build(:program_item, program: item.program, position: item.position)
    expect(duplicate).not_to be_valid
  end

  it "is visible by default" do
    expect(ProgramItem.new.hidden).to be(false)
  end

  describe "#display_title" do
    it "uses title_override first" do
      expect(build(:program_item, :lesson, title_override: "Override").display_title).to eq("Override")
    end

    it "falls back to the lesson title" do
      item = build(:program_item, :lesson)
      expect(item.display_title).to eq(item.lesson.title)
    end

    it "falls back to the book title" do
      item = build(:program_item, :book)
      expect(item.display_title).to eq(item.book.title)
    end

    it "falls back to the exam title" do
      item = build(:program_item, :exam)
      expect(item.display_title).to eq(item.exam.title)
    end
  end

  it "rejects an exam of another program" do
    item = build(:program_item, :exam)
    item.exam = create(:exam)
    expect(item).not_to be_valid
  end

  it "keeps a referenced lesson or book from being deleted" do
    lesson_item = create(:program_item, :lesson)
    book_item = create(:program_item, :book)
    expect(lesson_item.lesson.destroy).to be(false)
    expect(book_item.book.destroy).to be(false)
    expect(ProgramItem.count).to eq(2)
  end
end
