require "rails_helper"

RSpec.describe Cohort, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:riyadh) { Time.find_zone("Asia/Riyadh") }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:starts_on) }

  it "defaults to the Asia/Riyadh time zone" do
    expect(Cohort.new.time_zone).to eq("Asia/Riyadh")
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
