require "rails_helper"

RSpec.describe Programs::ReminderDigest do
  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let(:program) { create(:program) }
  let(:cohort) { create(:cohort, program: program, starts_on: Date.new(2025, 11, 8)) }
  let(:enrollment) { create(:enrollment, cohort: cohort) }
  let(:at) { riyadh.local(2025, 11, 19, 6, 5) }

  def digest
    described_class.new(enrollment, at: at)
  end

  def lesson_on(date, **attributes)
    item = create(:program_item, :lesson, program: program, **attributes)
    create(:cohort_slot, cohort: cohort, program_item: item, available_on: date)
    item
  end

  def exam_slot(opens_at:, closes_at:, questions: true, **attributes)
    item = create(:program_item, :exam, program: program, **attributes)
    create(:question, exam: item.exam) if questions
    create(:cohort_slot, cohort: cohort, program_item: item, available_on: opens_at.to_date, opens_at: opens_at, closes_at: closes_at)
  end

  it "uses the cohort-local date" do
    expect(described_class.new(enrollment, at: Time.utc(2025, 11, 18, 21, 0)).on).to eq(Date.new(2025, 11, 19))
  end

  it "lists lessons released today" do
    today = lesson_on(Date.new(2025, 11, 19))
    lesson_on(Date.new(2025, 11, 20))
    lesson_on(Date.new(2025, 11, 19), hidden: true)

    expect(digest.lessons).to eq([ today ])
  end

  it "includes an exam that opened at 00:00 today" do
    slot = exam_slot(opens_at: riyadh.local(2025, 11, 19), closes_at: riyadh.local(2025, 11, 21, 22))

    expect(digest.exams_opening).to eq([ slot ])
  end

  it "includes an exam opening before the next reminder but not after" do
    soon = exam_slot(opens_at: riyadh.local(2025, 11, 20), closes_at: riyadh.local(2025, 11, 22))
    exam_slot(opens_at: riyadh.local(2025, 11, 20, 6, 5), closes_at: riyadh.local(2025, 11, 22))

    expect(digest.exams_opening).to eq([ soon ])
  end

  it "includes an exam closing within 24 hours unless already submitted" do
    slot = exam_slot(opens_at: riyadh.local(2025, 11, 17), closes_at: riyadh.local(2025, 11, 19, 22))
    exam_slot(opens_at: riyadh.local(2025, 11, 17), closes_at: riyadh.local(2025, 11, 21))

    expect(digest.exams_closing).to eq([ slot ])

    create(:exam_attempt, enrollment: enrollment, exam: slot.program_item.exam)
    expect(digest.exams_closing).to be_empty
    expect(digest).to be_empty
  end

  it "still reminds about an exam started but not submitted" do
    slot = exam_slot(opens_at: riyadh.local(2025, 11, 17), closes_at: riyadh.local(2025, 11, 19, 22))
    create(:exam_attempt, enrollment: enrollment, exam: slot.program_item.exam, submitted_at: nil, score_percent: nil)

    expect(digest.exams_closing).to eq([ slot ])
  end

  it "ignores an exam that already closed" do
    exam_slot(opens_at: riyadh.local(2025, 11, 16), closes_at: riyadh.local(2025, 11, 19, 6))

    expect(digest).to be_empty
  end

  it "does not announce an exam that opened and closed before the reminder" do
    exam_slot(opens_at: riyadh.local(2025, 11, 19), closes_at: riyadh.local(2025, 11, 19, 5))

    expect(digest).to be_empty
  end

  it "does not announce an exam without questions or a hidden one" do
    exam_slot(opens_at: riyadh.local(2025, 11, 19), closes_at: riyadh.local(2025, 11, 19, 22), questions: false)
    exam_slot(opens_at: riyadh.local(2025, 11, 19), closes_at: riyadh.local(2025, 11, 19, 22), hidden: true)

    expect(digest).to be_empty
  end

  it "is empty on a day with nothing" do
    lesson_on(Date.new(2025, 11, 18))

    expect(digest).to be_empty
  end
end
