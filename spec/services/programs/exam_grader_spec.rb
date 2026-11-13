require "rails_helper"

RSpec.describe Programs::ExamGrader do
  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let(:program) { create(:program) }
  let(:cohort) { create(:cohort, program: program, starts_on: Date.new(2025, 11, 8)) }
  let(:enrollment) { create(:enrollment, cohort: cohort) }
  let(:exam) { create(:exam, :with_questions, program: program) }
  let(:exam_item) { create(:program_item, :exam, program: program, exam: exam) }
  let(:during_window) { riyadh.local(2025, 11, 20, 12) }
  let(:after_window) { riyadh.local(2025, 11, 21, 22) }

  before do
    create(:cohort_slot, cohort: cohort, program_item: exam_item, available_on: Date.new(2025, 11, 19),
                         opens_at: riyadh.local(2025, 11, 19), closes_at: riyadh.local(2025, 11, 21, 22))
  end

  def questions = exam.questions.includes(:choices).to_a
  def correct(question) = question.choices.find(&:correct?).id
  def wrong(question) = question.choices.reject(&:correct?).first.id

  def submit(answers, at: during_window)
    described_class.new(enrollment, exam_item, at: at).submit!(answers)
  end

  it "scores 2 of 3 correct as 67 and records the answers" do
    first, second, third = questions
    attempt = submit({ first.id => correct(first), second.id => correct(second), third.id => wrong(third) })

    expect(attempt.score_percent).to eq(67)
    expect(attempt.submitted_at).to eq(during_window)
    expect(attempt.started_at).to eq(during_window)
    expect(attempt.attempt_answers.pluck(:question_id, :choice_id)).to contain_exactly(
      [ first.id, correct(first) ], [ second.id, correct(second) ], [ third.id, wrong(third) ]
    )
    expect(attempt.passed?(60)).to be(true)
  end

  it "accepts the string ids a form posts" do
    first, = questions
    expect(submit({ first.id.to_s => correct(first).to_s }).score_percent).to eq(33)
  end

  it "counts unanswered questions as wrong" do
    first, = questions
    expect(submit({ first.id => correct(first) }).score_percent).to eq(33)
  end

  it "ignores a choice that belongs to another question" do
    first, second, = questions
    attempt = submit({ first.id => correct(second) })

    expect(attempt.score_percent).to eq(0)
    expect(attempt.attempt_answers).to be_empty
  end

  it "returns the existing attempt on a second submit and keeps its score" do
    first, second, third = questions
    stored = submit({ first.id => correct(first), second.id => correct(second), third.id => correct(third) })

    again = submit({}, at: during_window + 1.minute)

    expect(again).to eq(stored)
    expect(again.reload.score_percent).to eq(100)
    expect(ExamAttempt.count).to eq(1)
  end

  it "returns the stored attempt after the window closes" do
    stored = submit({})
    expect(submit({}, at: after_window)).to eq(stored)
  end

  it "creates one attempt under concurrent submits" do
    stored = create(:exam_attempt, enrollment: enrollment, exam: exam, score_percent: 100)
    # The other request committed after this one checked for an attempt.
    allow(ExamAttempt).to receive(:find_by).and_return(nil)
    allow(Programs::Progress).to receive(:new).and_return(instance_double(Programs::Progress, exam_state: :open))

    expect(submit({})).to eq(stored)
    expect(ExamAttempt.count).to eq(1)
    expect(stored.reload.score_percent).to eq(100)
  end

  it "refuses outside the window" do
    expect { submit({}, at: riyadh.local(2025, 11, 18, 23, 59)) }.to raise_error(described_class::NotOpen)
    expect { submit({}, at: after_window) }.to raise_error(described_class::NotOpen)
    expect(ExamAttempt.count).to eq(0)
  end

  it "refuses while earlier lessons are unticked" do
    lesson = create(:program_item, :lesson, program: program, position: exam_item.position - 1)
    create(:cohort_slot, cohort: cohort, program_item: lesson, available_on: Date.new(2025, 11, 8))

    expect { submit({}) }.to raise_error(described_class::NotOpen)
  end

  it "refuses an exam with no questions yet" do
    exam.questions.destroy_all
    expect { submit({}) }.to raise_error(described_class::NotOpen)
    expect(ExamAttempt.count).to eq(0)
  end

  it "makes the exam :submitted for the learner, even after the window" do
    submit({})
    expect(Programs::Progress.new(enrollment, at: during_window).exam_state(exam_item)).to eq(:submitted)
    expect(Programs::Progress.new(enrollment, at: after_window).exam_state(exam_item)).to eq(:submitted)
  end

  it "keeps a taken exam and its questions from being destroyed, saying why" do
    submit({ questions.first.id => correct(questions.first) })

    expect(exam.destroy).to be(false)
    expect(exam.errors).to be_of_kind(:base, :has_exam_attempts)
    expect(exam.reload.questions.count).to eq(3)
    expect(questions.first.destroy).to be(false)
  end

  it "keeps a program with exam attempts from being destroyed" do
    submit({})
    expect(program.destroy).to be(false)
    expect(program.errors).to be_of_kind(:base, :has_enrollments)
  end

  it "refuses an exam whose questions were removed after it was checked" do
    allow(Programs::Progress).to receive(:new).and_return(instance_double(Programs::Progress, exam_state: :open))
    exam.questions.destroy_all

    expect { submit({}) }.to raise_error(described_class::NotOpen)
  end
end
