require "rails_helper"

RSpec.describe Question, type: :model do
  def question_with(*correct_flags, kind: :single_choice)
    build(:question, kind: kind).tap do |question|
      correct_flags.each_with_index do |correct, index|
        question.choices.build(body: "Choice #{index}", position: index + 1, correct: correct)
      end
    end
  end

  it "can be saved before its choices exist" do
    expect(build(:question)).to be_valid
  end

  it "is valid only with exactly one correct choice" do
    expect(question_with(true, false, false)).to be_valid
    expect(question_with(false, false, false)).not_to be_valid
    expect(question_with(true, true, false)).not_to be_valid
  end

  it "ignores choices marked for destruction" do
    question = question_with(true, true)
    question.choices.last.mark_for_destruction
    expect(question).to be_valid
  end

  it "true_false questions have exactly two choices" do
    expect(question_with(true, false, kind: :true_false)).to be_valid
    expect(question_with(true, false, false, kind: :true_false)).not_to be_valid
  end

  it "returns its correct choice" do
    question = create(:question)
    create(:choice, question: question, position: 1, correct: false)
    right = create(:choice, question: question, position: 2, correct: true)
    expect(question.reload.correct_choice).to eq(right)
  end

  it "deletes the choices it was validated without" do
    question = create(:question, kind: :single_choice)
    create(:choice, question: question, position: 1, correct: true)
    create(:choice, question: question, position: 2, correct: false)
    create(:choice, question: question, position: 3, correct: false)
    question.reload.kind = :true_false
    question.choices.to_a.last.mark_for_destruction
    question.save!
    expect(question.reload.choices.size).to eq(2)
  end
end
