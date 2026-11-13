class Avo::Actions::GenerateCohortSchedule < Avo::BaseAction
  self.name = "Generate schedule"
  self.message = "Replaces every slot of the cohort with dates computed from this rule."

  WEEKDAYS = Date::DAYNAMES.each_with_index.to_h { |name, wday| [ name, wday.to_s ] }

  def fields
    field :weekdays, as: :select, multiple: true, options: WEEKDAYS, default: %w[0 1 2 3 4 6]
    field :lessons_per_day, as: :number, default: 1, min: 1
    field :exam_open_wday, as: :select, options: WEEKDAYS, default: "3", name: "Exam opens on"
    field :exam_close_wday, as: :select, options: WEEKDAYS, default: "5", name: "Exam closes on"
    field :exam_close_hour, as: :number, default: 22, min: 0, max: 23, help: "Hour the exam closes, in the cohort time zone"
    field :skip_ranges, as: :textarea, help: "Breaks, one per line: YYYY-MM-DD..YYYY-MM-DD"
  end

  def handle(records:, fields:, **)
    options = {
      weekdays: Array(fields[:weekdays]).compact_blank,
      lessons_per_day: fields[:lessons_per_day],
      exam_open_wday: fields[:exam_open_wday],
      exam_close_wday: fields[:exam_close_wday],
      exam_close_hour: fields[:exam_close_hour],
      skip_ranges: skip_ranges(fields[:skip_ranges])
    }
    records.each { |cohort| Programs::ScheduleGenerator.new(cohort, **options).call }
    succeed "Schedule generated"
  rescue ArgumentError, TypeError, ActiveRecord::RecordInvalid => e
    error e.message
    keep_modal_open
  end

  private

  def skip_ranges(text)
    text.to_s.lines.map(&:strip).compact_blank.map do |line|
      first, last = line.split("..", 2).map(&:strip)
      raise ArgumentError, "Invalid break “#{line}”: use YYYY-MM-DD..YYYY-MM-DD" if first.blank? || last.blank?

      Date.iso8601(first)..Date.iso8601(last)
    rescue Date::Error
      raise ArgumentError, "Invalid date in break “#{line}”"
    end
  end
end
