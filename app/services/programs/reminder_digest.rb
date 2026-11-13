module Programs
  # What one enrollment's morning reminder says, evaluated at `at` in the
  # cohort's time zone: today's lessons, exams opening between the start of
  # today and the next reminder, and exams closing before then that the
  # learner has not submitted.
  class ReminderDigest
    attr_reader :enrollment, :at

    def initialize(enrollment, at: Time.current)
      @enrollment = enrollment
      @at = at
    end

    def on
      @on ||= enrollment.cohort.today(at)
    end

    def lessons
      @lessons ||= progress.todays_items.select(&:lesson?)
    end

    def exams_opening
      @exams_opening ||= exam_slots.select { |slot| slot.opens_at >= start_of_day && slot.opens_at < next_reminder }
    end

    def exams_closing
      @exams_closing ||= exam_slots.select { |slot| slot.closes_at > at && slot.closes_at <= next_reminder }
    end

    def empty?
      lessons.empty? && exams_opening.empty? && exams_closing.empty?
    end

    private

    def progress
      @progress ||= Progress.new(enrollment, at: at)
    end

    def start_of_day
      on.in_time_zone(enrollment.cohort.time_zone)
    end

    def next_reminder
      at + 24.hours
    end

    # Exams the learner can still act on: visible, with a window, not submitted.
    def exam_slots
      @exam_slots ||= progress.exam_items
        .reject { |item| progress.exam_state(item) == :submitted }
        .filter_map { |item| progress.slot_for(item) }
        .select { |slot| slot.opens_at && slot.closes_at }
        .sort_by(&:opens_at)
    end
  end
end
