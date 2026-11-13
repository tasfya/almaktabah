require "rails_helper"

RSpec.describe Cohort, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:riyadh) { Time.find_zone("Asia/Riyadh") }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:starts_on) }

  it "defaults to the Asia/Riyadh time zone" do
    expect(Cohort.new.time_zone).to eq("Asia/Riyadh")
  end

  it "refuses a time zone change once it has slots, which were placed in the old zone" do
    cohort = create(:cohort_slot).cohort

    expect(cohort.update(time_zone: "Europe/London")).to be(false)
    expect(cohort.errors).to be_of_kind(:time_zone, :kept_while_scheduled)
    expect(cohort.reload.time_zone).to eq("Asia/Riyadh")
  end

  it "accepts a time zone change before any slot exists" do
    cohort = create(:cohort)
    expect(cohort.update(time_zone: "Europe/London")).to be(true)
  end

  it "rejects an unknown time zone" do
    expect(build(:cohort, time_zone: "Mars/Olympus")).not_to be_valid
  end

  it "computes today in its time zone" do
    travel_to Time.utc(2025, 11, 8, 21, 30) do
      expect(build(:cohort).today).to eq(Date.new(2025, 11, 9))
    end
  end

  it "computes the date at a given time in its time zone" do
    expect(build(:cohort).today(Time.utc(2025, 11, 8, 20, 59))).to eq(Date.new(2025, 11, 8))
  end

  describe "enrollment" do
    let(:cohort) { create(:cohort) }

    def add_exam_slot(closes_at)
      item = create(:program_item, :exam, program: cohort.program)
      create(:cohort_slot, cohort: cohort, program_item: item, opens_at: closes_at - 2.days, closes_at: closes_at)
    end

    it "closes by default when the first exam closes" do
      first_close = riyadh.local(2025, 11, 21, 22)
      add_exam_slot(riyadh.local(2025, 12, 5, 22))
      add_exam_slot(first_close)
      expect(cohort.enrollment_deadline).to eq(first_close)
      expect(cohort.enrollment_open?(first_close - 1.minute)).to be(true)
      expect(cohort.enrollment_open?(first_close)).to be(false)
    end

    it "follows an exam slot edited by hand" do
      slot = add_exam_slot(riyadh.local(2025, 11, 21, 22))
      slot.update!(closes_at: riyadh.local(2025, 11, 28, 22))
      expect(cohort.enrollment_open?(riyadh.local(2025, 11, 25, 12))).to be(true)
    end

    it "uses the deadline an admin set over the default" do
      chosen = riyadh.local(2025, 11, 30, 12)
      add_exam_slot(riyadh.local(2025, 11, 21, 22))
      cohort.update!(enrollment_closes_at: chosen)
      expect(cohort.enrollment_deadline).to eq(chosen)
      expect(cohort.enrollment_open?(riyadh.local(2025, 11, 25, 12))).to be(true)
      expect(cohort.enrollment_open?(chosen)).to be(false)
    end

    it "stays open forever without exams" do
      expect(cohort.enrollment_deadline).to be_nil
      expect(cohort.enrollment_open?(10.years.from_now)).to be(true)
    end
  end

  it "separates its lesson and exam slots" do
    cohort = create(:cohort)
    lesson = create(:cohort_slot, cohort: cohort, program_item: create(:program_item, :lesson, program: cohort.program))
    create(:cohort_slot, cohort: cohort, program_item: create(:program_item, :book, program: cohort.program))
    exam = create(:cohort_slot, :exam, cohort: cohort)

    expect(cohort.lesson_slots).to eq([ lesson ])
    expect(cohort.exam_slots).to eq([ exam ])
  end

  describe "#clear_schedule!" do
    let(:cohort) { create(:cohort) }

    before do
      create(:cohort_slot, cohort: cohort)
      create(:cohort_slot, :exam, cohort: cohort)
    end

    it "deletes the slots while no learner has progress, enrollments or not" do
      create(:enrollment, cohort: cohort)

      expect(cohort.clear_schedule!).to be(true)
      expect(cohort.cohort_slots.count).to eq(0)
    end

    it "is refused once a learner ticked a lesson" do
      create(:lesson_completion, enrollment: create(:enrollment, cohort: cohort))

      expect(cohort.clear_schedule!).to be(false)
      expect(cohort.errors[:base]).to be_present
      expect(cohort.cohort_slots.count).to eq(2)
    end

    it "is refused once a learner took an exam" do
      create(:exam_attempt, enrollment: create(:enrollment, cohort: cohort))

      expect(cohort.clear_schedule!).to be(false)
      expect(cohort.cohort_slots.count).to eq(2)
    end

    it "ignores progress in another cohort" do
      create(:lesson_completion)

      expect(cohort.clear_schedule!).to be(true)
    end
  end

  it "lists the scheduled exams that have no questions" do
    cohort = create(:cohort)
    empty = create(:cohort_slot, :exam, cohort: cohort).program_item.exam
    ready = create(:exam, :with_questions, program: cohort.program)
    create(:cohort_slot, :exam, cohort: cohort, program_item: create(:program_item, :exam, program: cohort.program, exam: ready))
    create(:exam, program: cohort.program)

    expect(cohort.exams_without_questions).to eq([ empty ])
  end

  it "is destroyed with its program, slots included" do
    cohort = create(:cohort)
    create(:cohort_slot, cohort: cohort)
    create(:cohort_slot, :exam, cohort: cohort)
    expect { cohort.program.destroy! }
      .to change(Cohort, :count).by(-1)
      .and change(CohortSlot, :count).by(-2)
      .and change(Exam, :count).by(-1)
  end
end
