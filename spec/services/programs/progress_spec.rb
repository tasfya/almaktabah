require "rails_helper"

RSpec.describe Programs::Progress do
  include ActiveSupport::Testing::TimeHelpers

  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let(:program) { create(:program) }
  let(:cohort) { create(:cohort, program: program, starts_on: Date.new(2025, 11, 8)) }
  let(:enrollment) { create(:enrollment, cohort: cohort) }

  def item(kind, **attributes)
    create(:program_item, kind, program: program, **attributes)
  end

  def slot(program_item, on:, opens_at: nil, closes_at: nil)
    create(:cohort_slot, cohort: cohort, program_item: program_item, available_on: on, opens_at: opens_at, closes_at: closes_at)
    program_item
  end

  def exam_slot(program_item)
    slot(program_item, on: Date.new(2025, 11, 19), opens_at: riyadh.local(2025, 11, 19), closes_at: riyadh.local(2025, 11, 21, 22))
  end

  def progress(at)
    described_class.new(enrollment, at: at)
  end

  let(:first_day) { riyadh.local(2025, 11, 8, 9) }

  describe "#tick!" do
    let!(:lesson) { slot(item(:lesson), on: Date.new(2025, 11, 9)) }

    it "cannot tick a lesson before its date" do
      expect { progress(first_day).tick!(lesson) }.to raise_error(described_class::NotAllowed)
      expect(LessonCompletion.count).to eq(0)
    end

    it "counts the date in the cohort time zone" do
      expect(progress(Time.utc(2025, 11, 8, 20, 59)).tickable?(lesson)).to be(false)
      expect(progress(Time.utc(2025, 11, 8, 21, 0)).tickable?(lesson)).to be(true)
    end

    it "ticks an available lesson once, stamped with the given time" do
      at = riyadh.local(2025, 11, 9, 10)
      tracker = progress(at)

      completion = tracker.tick!(lesson)

      expect(completion.completed_at).to eq(at)
      expect { tracker.tick!(lesson) }.to raise_error(described_class::NotAllowed)
      expect { progress(at).tick!(lesson) }.to raise_error(described_class::NotAllowed)
      expect(LessonCompletion.count).to eq(1)
    end

    it "does not tick books or hidden items" do
      book = slot(item(:book), on: Date.new(2025, 11, 8))
      hidden = slot(item(:lesson, hidden: true), on: Date.new(2025, 11, 8))

      tracker = progress(first_day)
      expect(tracker.available?(book)).to be(true)
      expect(tracker.available?(hidden)).to be(false)
      expect { tracker.tick!(book) }.to raise_error(described_class::NotAllowed)
      expect { tracker.tick!(hidden) }.to raise_error(described_class::NotAllowed)
    end

    it "does not tick a lesson without a slot in this cohort" do
      unscheduled = item(:lesson)
      expect { progress(first_day + 1.year).tick!(unscheduled) }.to raise_error(described_class::NotAllowed)
    end

    it "does not tick an item of another program" do
      foreign = create(:cohort_slot, available_on: Date.new(2025, 11, 1)).program_item
      expect { progress(first_day).tick!(foreign) }.to raise_error(described_class::NotAllowed)
    end
  end

  describe "#exam_state" do
    let!(:lesson_one) { slot(item(:lesson, position: 1), on: Date.new(2025, 11, 8)) }
    let!(:lesson_two) { slot(item(:lesson, position: 2), on: Date.new(2025, 11, 9)) }
    let!(:exam) { exam_slot(item(:exam, position: 3, exam: create(:exam, :with_questions, program: program))) }
    let!(:later_lesson) { slot(item(:lesson, position: 4), on: Date.new(2025, 11, 15)) }
    let(:during_window) { riyadh.local(2025, 11, 20, 12) }

    def tick_all(*lessons)
      lessons.each { |lesson| progress(during_window).tick!(lesson) }
    end

    it "is :locked before the window opens" do
      tick_all(lesson_one, lesson_two)
      expect(progress(riyadh.local(2025, 11, 18, 23, 59)).exam_state(exam)).to eq(:locked)
    end

    it "keeps the exam :not_ready until every earlier-position lesson is ticked, ignoring later lessons already released" do
      tick_all(lesson_one)
      expect(progress(during_window).exam_state(exam)).to eq(:not_ready)

      tick_all(lesson_two)
      expect(progress(during_window).exam_state(exam)).to eq(:open)
      expect(progress(during_window).available?(later_lesson)).to be(true)
    end

    it "does not wait for a hidden lesson the learner cannot tick" do
      slot(item(:lesson, position: 0, hidden: true), on: Date.new(2025, 11, 8))
      tick_all(lesson_one, lesson_two)
      expect(progress(during_window).exam_state(exam)).to eq(:open)
    end

    it "does not wait for an earlier lesson that has no slot in this cohort" do
      item(:lesson, position: 0)
      tick_all(lesson_one, lesson_two)
      expect(progress(during_window).exam_state(exam)).to eq(:open)
    end

    it "opens the exam at 00:00 and closes at 22:00 in the cohort time zone" do
      tick_all(lesson_one, lesson_two)
      expect(progress(riyadh.local(2025, 11, 19, 0, 0)).exam_state(exam)).to eq(:open)
      expect(progress(riyadh.local(2025, 11, 21, 21, 59)).exam_state(exam)).to eq(:open)
      expect(progress(riyadh.local(2025, 11, 21, 22, 0)).exam_state(exam)).to eq(:missed)
    end

    it "evaluates at the given time, not the clock" do
      tick_all(lesson_one, lesson_two)
      travel_to riyadh.local(2026, 1, 1) do
        expect(progress(during_window).exam_state(exam)).to eq(:open)
      end
    end

    it "reports :missed after the window with no attempt, even with lessons unticked" do
      expect(progress(riyadh.local(2025, 11, 22)).exam_state(exam)).to eq(:missed)
    end

    it "is :locked for an exam without a slot in this cohort" do
      unscheduled = item(:exam, position: 5)
      expect(progress(during_window).exam_state(unscheduled)).to eq(:locked)
    end

    it "is :locked for a hidden exam" do
      hidden = exam_slot(item(:exam, position: 5, hidden: true, exam: create(:exam, :with_questions, program: program)))
      tick_all(lesson_one, lesson_two)
      expect(progress(during_window).exam_state(hidden)).to eq(:locked)
    end

    context "when the exam has no questions yet" do
      let!(:placeholder) { exam_slot(item(:exam, position: 5)) }

      it "stays :locked inside and after its window" do
        tick_all(lesson_one, lesson_two, later_lesson)
        expect(progress(during_window).exam_state(placeholder)).to eq(:locked)
        expect(progress(riyadh.local(2025, 11, 22)).exam_state(placeholder)).to eq(:locked)
      end
    end
  end

  describe "exams in the cohort" do
    it "ignores exams that have no slot in this cohort" do
      lesson = slot(item(:lesson, position: 1), on: Date.new(2025, 11, 8))
      scheduled = exam_slot(item(:exam, position: 2))
      item(:exam, position: 3)

      tracker = progress(first_day)
      expect(tracker.exam_items).to eq([ scheduled ])
      expect(tracker.lesson_items).to eq([ lesson ])
    end
  end

  describe "#percent_complete" do
    it "counts ticked lessons over the cohort's lessons, ignoring books, hidden and unscheduled lessons" do
      lessons = (1..3).map { |n| slot(item(:lesson, position: n), on: Date.new(2025, 11, 8)) }
      slot(item(:book, position: 4), on: Date.new(2025, 11, 8))
      slot(item(:lesson, position: 5, hidden: true), on: Date.new(2025, 11, 8))
      item(:lesson, position: 6)

      expect(progress(first_day).percent_complete).to eq(0)
      progress(first_day).tick!(lessons.first)
      expect(progress(first_day).percent_complete).to eq(33)
      lessons.drop(1).each { |lesson| progress(first_day).tick!(lesson) }
      expect(progress(first_day).percent_complete).to eq(100)
    end

    it "is 0 for a cohort without lessons" do
      expect(progress(first_day).percent_complete).to eq(0)
    end
  end

  describe "#todays_items" do
    it "lists the visible items released today in position order" do
      exam = exam_slot(item(:exam, position: 1))
      second = slot(item(:lesson, position: 3), on: Date.new(2025, 11, 19))
      first = slot(item(:book, position: 2), on: Date.new(2025, 11, 19))
      slot(item(:lesson, position: 4, hidden: true), on: Date.new(2025, 11, 19))
      slot(item(:lesson, position: 5), on: Date.new(2025, 11, 18))

      expect(progress(riyadh.local(2025, 11, 19, 8)).todays_items).to eq([ exam, first, second ])
    end
  end
end
