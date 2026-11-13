require "rails_helper"

RSpec.describe Programs::ScheduleGenerator do
  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let(:program) { create(:program) }
  let(:cohort) { create(:cohort, program: program, starts_on: Date.new(2025, 11, 8)) }
  let(:sat_sun_mon) { [ 6, 0, 1 ] }

  def add_items(*kinds)
    kinds.map { |kind| create(:program_item, kind, program: program) }
  end

  def generate(**options)
    described_class.new(cohort, weekdays: sat_sun_mon, **options).call
    cohort.reload
  end

  def dates_of(items)
    items.map { |item| cohort.cohort_slots.find_by!(program_item: item).available_on }
  end

  def slot_for(item)
    cohort.cohort_slots.find_by!(program_item: item)
  end

  context "with a book, four lessons and an exam" do
    let!(:book) { add_items(:book).first }
    let!(:lessons) { add_items(:lesson, :lesson, :lesson, :lesson) }
    let!(:exam) { add_items(:exam).first }

    it "releases the book with the first lesson and one lesson per teaching day" do
      generate
      expect(slot_for(book).available_on).to eq(Date.new(2025, 11, 8))
      expect(dates_of(lessons)).to eq([ Date.new(2025, 11, 8), Date.new(2025, 11, 9), Date.new(2025, 11, 10), Date.new(2025, 11, 15) ])
    end

    it "opens the exam the Wednesday after the last lesson and closes it Friday 22:00 cohort time" do
      generate
      exam_slot = slot_for(exam)
      expect(exam_slot.opens_at).to eq(riyadh.local(2025, 11, 19, 0, 0))
      expect(exam_slot.closes_at).to eq(riyadh.local(2025, 11, 21, 22, 0))
      expect(exam_slot.available_on).to eq(Date.new(2025, 11, 19))
    end

    it "skips skip_ranges" do
      generate(skip_ranges: [ Date.new(2025, 11, 9)..Date.new(2025, 11, 10) ])
      expect(dates_of(lessons)).to eq([ Date.new(2025, 11, 8), Date.new(2025, 11, 15), Date.new(2025, 11, 16), Date.new(2025, 11, 17) ])
    end

    it "moves the exam to the next week when its opening day is skipped" do
      generate(skip_ranges: [ Date.new(2025, 11, 19)..Date.new(2025, 11, 19) ])
      expect(slot_for(exam).opens_at).to eq(riyadh.local(2025, 11, 26, 0, 0))
      expect(slot_for(exam).closes_at).to eq(riyadh.local(2025, 11, 28, 22, 0))
    end

    it "is idempotent: running twice leaves one slot per item" do
      generate
      generate
      expect(cohort.cohort_slots.count).to eq(6)
    end

    it "makes the first exam close the default enrollment deadline" do
      generate
      expect(cohort.enrollment_deadline).to eq(riyadh.local(2025, 11, 21, 22, 0))
    end
  end

  it "releases several lessons a day" do
    lessons = add_items(:lesson, :lesson, :lesson)
    generate(lessons_per_day: 2)
    expect(dates_of(lessons)).to eq([ Date.new(2025, 11, 8), Date.new(2025, 11, 8), Date.new(2025, 11, 9) ])
  end

  it "releases a book after a full day with the next lesson" do
    first, book, second = add_items(:lesson, :book, :lesson)
    generate
    expect(dates_of([ first, book, second ])).to eq([ Date.new(2025, 11, 8), Date.new(2025, 11, 9), Date.new(2025, 11, 9) ])
  end

  it "continues lessons from the last lesson day, during the exam window" do
    items = add_items(:lesson, :lesson, :lesson, :lesson, :exam, :lesson)
    generate
    expect(slot_for(items.last).available_on).to eq(Date.new(2025, 11, 16))
  end

  it "opens an exam with no lesson before it on the first opening day from the start" do
    exam = add_items(:exam).first
    generate
    expect(slot_for(exam).opens_at).to eq(riyadh.local(2025, 11, 12, 0, 0))
  end

  it "rejects an empty weekday list" do
    expect { described_class.new(cohort, weekdays: []).call }.to raise_error(ArgumentError)
  end

  it "rejects weekdays and hours out of range" do
    expect { described_class.new(cohort, weekdays: [ 7 ]) }.to raise_error(ArgumentError)
    expect { described_class.new(cohort, weekdays: sat_sun_mon, exam_open_wday: 9) }.to raise_error(ArgumentError)
    expect { described_class.new(cohort, weekdays: sat_sun_mon, exam_close_hour: 24) }.to raise_error(ArgumentError)
    expect { described_class.new(cohort, weekdays: sat_sun_mon, lessons_per_day: 0) }.to raise_error(ArgumentError)
  end

  it "rejects endless skip ranges" do
    expect { described_class.new(cohort, weekdays: sat_sun_mon, skip_ranges: [ Date.new(2025, 11, 9).. ]) }.to raise_error(ArgumentError)
  end

  it "accepts form strings" do
    lesson, exam = add_items(:lesson, :exam)
    described_class.new(cohort, weekdays: %w[6 0 1], exam_open_wday: "3", exam_close_wday: "5", exam_close_hour: "22").call
    expect(slot_for(exam).closes_at).to eq(riyadh.local(2025, 11, 14, 22, 0))
    expect(slot_for(lesson).available_on).to eq(Date.new(2025, 11, 8))
  end

  it "moves the default enrollment deadline when regenerating" do
    add_items(:lesson, :exam)
    generate
    cohort.update!(starts_on: Date.new(2025, 11, 15))
    generate
    expect(cohort.enrollment_deadline).to eq(riyadh.local(2025, 11, 21, 22, 0))
  end

  it "keeps an enrollment deadline chosen by an admin when regenerating" do
    chosen = riyadh.local(2025, 12, 1, 12, 0)
    add_items(:lesson, :exam)
    generate
    cohort.update!(enrollment_closes_at: chosen)
    generate
    expect(cohort.enrollment_deadline).to eq(chosen)
  end
end
