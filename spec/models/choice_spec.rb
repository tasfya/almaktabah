require "rails_helper"

RSpec.describe Choice, type: :model do
  let(:question) { create(:question) }

  it "cannot become a second correct choice when saved on its own" do
    create(:choice, question: question, position: 1, correct: true)
    wrong = create(:choice, question: question, position: 2, correct: false)
    expect(wrong.update(correct: true)).to be(false)
    expect(wrong.errors.full_messages.join).to include("جواب صحيح واحد")
    expect(question.choices.where(correct: true).count).to eq(1)
  end

  it "lets the correct answer move to another choice when saved through the question" do
    first = create(:choice, question: question, position: 1, correct: true)
    second = create(:choice, question: question, position: 2, correct: false)
    question.reload
    question.choices.each { |choice| choice.correct = choice == second }
    question.save!
    expect(first.reload.correct).to be(false)
    expect(second.reload.correct).to be(true)
  end

  it "cannot add a third choice to a true/false question" do
    question.update!(kind: :true_false)
    create(:choice, question: question, position: 1, correct: true)
    create(:choice, question: question, position: 2, correct: false)
    third = build(:choice, question: question, position: 3)
    expect(third).not_to be_valid
    expect(third.errors.full_messages.join).to include("خياران")
  end
end
