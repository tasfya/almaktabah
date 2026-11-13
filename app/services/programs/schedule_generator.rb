module Programs
  # Replaces a cohort's slots with dates computed from a weekly rule.
  # Books are released with the next lesson and take no lesson place. An exam
  # opens on the first exam_open_wday after the last lesson before it; lessons
  # after it keep going from that last lesson day, so the next text can start
  # during the exam window.
  class ScheduleGenerator
    def initialize(cohort, weekdays:, lessons_per_day: 1, exam_open_wday: 3, exam_close_wday: 5, exam_close_hour: 22, skip_ranges: [])
      raise ArgumentError, "weekdays must not be empty" if weekdays.blank?
      raise ArgumentError, "lessons_per_day must be positive" unless lessons_per_day.to_i.positive?

      @cohort = cohort
      @weekdays = weekdays.map(&:to_i)
      @lessons_per_day = lessons_per_day.to_i
      @exam_open_wday = exam_open_wday
      @exam_close_wday = exam_close_wday
      @exam_close_hour = exam_close_hour
      @skip_ranges = skip_ranges
      @zone = ActiveSupport::TimeZone[cohort.time_zone]
    end

    def call
      attributes = slot_attributes
      CohortSlot.transaction do
        CohortSlot.where(cohort: @cohort).delete_all
        attributes.each { |slot| @cohort.cohort_slots.create!(slot) }
        @cohort.cohort_slots.reset
        @cohort.save!
      end
    end

    private

    def slot_attributes
      day = nil
      released_today = 0
      last_lesson_on = @cohort.starts_on - 1

      @cohort.program.program_items.map do |item|
        next exam_slot(item, after: last_lesson_on) if item.exam?

        if day.nil? || released_today >= @lessons_per_day
          day = next_teaching_day(day ? day + 1 : @cohort.starts_on)
          released_today = 0
        end
        if item.lesson?
          released_today += 1
          last_lesson_on = day
        end
        { program_item: item, available_on: day }
      end
    end

    def exam_slot(item, after:)
      opens_on = after + 1
      opens_on += 1 until opens_on.wday == @exam_open_wday && !skipped?(opens_on)
      closes_on = opens_on + (@exam_close_wday - @exam_open_wday) % 7
      {
        program_item: item,
        available_on: opens_on,
        opens_at: @zone.local(opens_on.year, opens_on.month, opens_on.day),
        closes_at: @zone.local(closes_on.year, closes_on.month, closes_on.day, @exam_close_hour)
      }
    end

    def next_teaching_day(from)
      day = from
      day += 1 until @weekdays.include?(day.wday) && !skipped?(day)
      day
    end

    def skipped?(date)
      @skip_ranges.any? { |range| range.cover?(date) }
    end
  end
end
