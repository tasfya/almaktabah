require "rails_helper"

RSpec.describe Exam, type: :model do
  it { is_expected.to validate_presence_of(:title) }

  it "orders its questions by position" do
    exam = create(:exam)
    later = create(:question, exam: exam, position: 2)
    earlier = create(:question, exam: exam, position: 1)
    expect(exam.questions).to eq([ earlier, later ])
  end

  it "destroys questions and choices with the exam" do
    exam = create(:exam, :with_questions)
    expect { exam.destroy! }
      .to change(Question, :count).by(-3)
      .and change(Choice, :count).by(-9)
  end

  it "destroys the program items that reference it" do
    item = create(:program_item, :exam)
    expect { item.exam.destroy! }.to change(ProgramItem, :count).by(-1)
  end

  it "builds three single-choice questions with the first choice correct" do
    exam = create(:exam, :with_questions)
    expect(exam.questions.map { |q| [ q.kind, q.choices.size, q.correct_choice ] })
      .to all(match([ "single_choice", 3, have_attributes(position: 1) ]))
  end

  it "cannot move to another program while a program item uses it" do
    item = create(:program_item, :exam)
    expect(item.exam.update(program: create(:program))).to be(false)
  end
end
