require "rails_helper"

RSpec.describe Programs::ScheduleShifter do
  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let(:cohort) { create(:cohort) }

  def lesson_slot(date)
    create(:cohort_slot, cohort: cohort, program_item: create(:program_item, :lesson, program: cohort.program), available_on: date)
  end

  it "moves slots on or after the date by N days and leaves earlier ones" do
    before = lesson_slot(Date.new(2026, 2, 17))
    on = lesson_slot(Date.new(2026, 2, 18))
    exam = create(:cohort_slot, :exam, cohort: cohort,
      available_on: Date.new(2026, 3, 4),
      opens_at: riyadh.local(2026, 3, 4, 0, 0),
      closes_at: riyadh.local(2026, 3, 6, 22, 0))

    described_class.new(cohort, after: Date.new(2026, 2, 18), days: 21).call

    expect(before.reload.available_on).to eq(Date.new(2026, 2, 17))
    expect(on.reload.available_on).to eq(Date.new(2026, 3, 11))
    exam.reload
    expect(exam.available_on).to eq(Date.new(2026, 3, 25))
    expect(exam.opens_at).to eq(riyadh.local(2026, 3, 25, 0, 0))
    expect(exam.closes_at).to eq(riyadh.local(2026, 3, 27, 22, 0))
  end

  it "keeps the wall-clock time in a zone with daylight saving" do
    berlin = Time.find_zone("Europe/Berlin")
    cohort.update!(time_zone: "Europe/Berlin")
    exam = create(:cohort_slot, :exam, cohort: cohort,
      available_on: Date.new(2026, 3, 25),
      opens_at: berlin.local(2026, 3, 25, 0, 0),
      closes_at: berlin.local(2026, 3, 27, 22, 0))

    described_class.new(cohort, after: Date.new(2026, 3, 1), days: 7).call

    expect(exam.reload.closes_at).to eq(berlin.local(2026, 4, 3, 22, 0))
  end

  it "does not touch other cohorts" do
    other = create(:cohort_slot, available_on: Date.new(2026, 2, 20))
    described_class.new(cohort, after: Date.new(2026, 2, 18), days: 7).call
    expect(other.reload.available_on).to eq(Date.new(2026, 2, 20))
  end
end
