class Avo::Actions::ShiftCohortSchedule < Avo::BaseAction
  self.name = "Shift schedule"
  self.message = "Moves every slot released on or after the date by the number of days (a break)."

  def fields
    field :after, as: :date, name: "From date"
    field :days, as: :number, help: "Negative values move slots earlier"
  end

  def handle(records:, fields:, **)
    raise ArgumentError, "From date is required" if fields[:after].blank?

    after = Date.iso8601(fields[:after].to_s)
    records.each { |cohort| Programs::ScheduleShifter.new(cohort, after: after, days: fields[:days]).call }
    succeed "Schedule shifted"
  rescue ArgumentError, TypeError, ActiveRecord::RecordInvalid => e
    error e.message
    keep_modal_open
  end
end
