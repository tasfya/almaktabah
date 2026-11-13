module Programs
  # Moves every slot released on or after a date by a number of days (a
  # break), keeping exam windows at the same wall-clock time in the cohort zone.
  class ScheduleShifter
    def initialize(cohort, after:, days:)
      @cohort = cohort
      @after = after.to_date
      @days = Integer(days)
      @zone = ActiveSupport::TimeZone[cohort.time_zone]
    end

    def call
      @cohort.reschedule do
        @cohort.cohort_slots.where(available_on: @after..).find_each do |slot|
          slot.update!(
            available_on: slot.available_on + @days,
            opens_at: shift(slot.opens_at),
            closes_at: shift(slot.closes_at)
          )
        end
      end
    end

    private

    def shift(time)
      time && time.in_time_zone(@zone) + @days.days
    end
  end
end
