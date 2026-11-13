require "rails_helper"

RSpec.describe Programs::CertificateIssuer do
  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let(:program) { create(:program) }
  let(:cohort) { create(:cohort, program: program, starts_on: Date.new(2025, 11, 8)) }
  let(:learner) { create(:learner, full_name: "فاطمة بنت عبد الله", gender: :female) }
  let(:enrollment) { create(:enrollment, cohort: cohort, learner: learner) }
  let(:after_lessons) { riyadh.local(2025, 11, 10, 9) }

  let!(:lessons) do
    (1..2).map do |n|
      item = create(:program_item, :lesson, program: program, position: n)
      create(:cohort_slot, cohort: cohort, program_item: item, available_on: Date.new(2025, 11, 7 + n))
      item
    end
  end

  def add_exam(position, exam: create(:exam, :with_questions, program: program))
    item = create(:program_item, :exam, program: program, position: position, exam: exam)
    create(:cohort_slot, cohort: cohort, program_item: item, available_on: Date.new(2025, 11, 19),
                         opens_at: riyadh.local(2025, 11, 19), closes_at: riyadh.local(2025, 11, 21, 22))
    item
  end

  def tick_all
    lessons.each { |lesson| create(:lesson_completion, enrollment: enrollment, program_item: lesson) }
  end

  def attempt(exam_item, score)
    create(:exam_attempt, enrollment: enrollment, exam: exam_item.exam, score_percent: score)
  end

  def issue = described_class.new(enrollment).call

  it "issues when all lessons are ticked and all exams passed (>= 60)" do
    exam = add_exam(3)
    tick_all
    attempt(exam, 60)

    certificate = issue

    expect(certificate).to be_persisted
    expect(certificate.number).to match(/\A#{cohort.id}-[A-HJ-NP-Z2-9]{8}\z/)
    expect(certificate.domain).to eq(enrollment.domain)
    expect(enrollment.reload.completed_at).to be_present
  end

  it "does not issue with one exam at 59" do
    tick_all
    attempt(add_exam(3), 100)
    attempt(add_exam(4), 59)

    expect(issue).to be_nil
    expect(enrollment.reload.completed_at).to be_nil
  end

  it "does not issue with a missed exam" do
    add_exam(3)
    tick_all
    expect(issue).to be_nil
  end

  it "does not issue while a cohort exam has no questions yet" do
    add_exam(3, exam: create(:exam, program: program))
    tick_all
    expect(issue).to be_nil
  end

  it "does not issue with a lesson unticked" do
    create(:lesson_completion, enrollment: enrollment, program_item: lessons.first)
    expect(issue).to be_nil
  end

  it "ignores exams and lessons the cohort does not schedule or hides" do
    create(:program_item, :exam, program: program, position: 3)
    hidden = create(:program_item, :lesson, program: program, position: 4, hidden: true)
    create(:cohort_slot, cohort: cohort, program_item: hidden, available_on: Date.new(2025, 11, 8))
    tick_all

    expect(issue).to be_present
  end

  it "does not let a hidden exam block the certificate" do
    hidden = create(:program_item, :exam, program: program, position: 3, hidden: true)
    create(:cohort_slot, cohort: cohort, program_item: hidden, available_on: Date.new(2025, 11, 19),
                         opens_at: riyadh.local(2025, 11, 19), closes_at: riyadh.local(2025, 11, 21, 22))
    tick_all

    expect(issue).to be_present
  end

  it "issues on completion of every lesson for a cohort without exams" do
    tick_all
    expect(issue).to be_present
  end

  it "never issues for a cohort with nothing scheduled" do
    empty = create(:enrollment, cohort: create(:cohort, program: program))
    expect(described_class.new(empty).call).to be_nil
  end

  it "is idempotent" do
    tick_all
    first = issue
    expect(issue).to eq(first)
    expect(Certificate.count).to eq(1)
  end

  it "snapshots name and gender at issue time" do
    tick_all
    certificate = issue
    learner.update!(full_name: "اسم آخر", gender: :male)

    expect(certificate.reload.full_name_snapshot).to eq("فاطمة بنت عبد الله")
    expect(certificate.gender_snapshot).to eq("female")
  end

  it "is issued by the last tick" do
    tracker = Programs::Progress.new(enrollment, at: after_lessons)
    tracker.tick!(lessons.first)
    expect(Certificate.count).to eq(0)

    tracker.tick!(lessons.last)

    certificate = enrollment.reload.certificate
    expect(certificate.issued_at).to eq(after_lessons)
    expect(enrollment.completed_at).to eq(after_lessons)
  end

  it "is issued by a passing final exam submit" do
    exam_item = add_exam(3)
    tick_all
    answers = exam_item.exam.questions.to_h { |question| [ question.id, question.correct_choice.id ] }

    Programs::ExamGrader.new(enrollment, exam_item, at: riyadh.local(2025, 11, 20, 12)).submit!(answers)

    expect(enrollment.reload.certificate).to be_present
  end

  it "is not issued by a failing exam submit" do
    exam_item = add_exam(3)
    tick_all

    Programs::ExamGrader.new(enrollment, exam_item, at: riyadh.local(2025, 11, 20, 12)).submit!({})

    expect(enrollment.reload.certificate).to be_nil
  end

  it "survives the learner deleting their account, with no enrollment" do
    tick_all
    certificate = issue

    learner.destroy!

    expect(Enrollment.count).to eq(0)
    expect(LessonCompletion.count).to eq(0)
    expect(Certificate.find_by(number: certificate.number)).to have_attributes(enrollment_id: nil, domain_id: certificate.domain_id)
  end
end
