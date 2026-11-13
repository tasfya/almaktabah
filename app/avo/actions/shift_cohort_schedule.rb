class Avo::Actions::ShiftCohortSchedule < Avo::BaseAction
  self.name = "إزاحة الجدول"
  self.message = "ينقل كل موعد يبدأ في هذا التاريخ أو بعده بعدد الأيام المحدد (للإجازات). تتغير تواريخ الطلاب المسجلين."

  # Avo's date picker posts YYYY/MM/DD; ISO YYYY-MM-DD is accepted too.
  DATE_FORMAT = %r{\A(\d{4})([/-])(\d{2})\2(\d{2})\z}

  def fields
    field :after, as: :date, name: "من تاريخ", required: true
    field :days, as: :number, name: "عدد الأيام", required: true, help: "قيمة سالبة تقدّم المواعيد"
  end

  def handle(records:, fields:, **)
    raise ArgumentError, "«من تاريخ» مطلوب" if fields[:after].blank?

    after = parse_date(fields[:after].to_s)
    records.each { |cohort| Programs::ScheduleShifter.new(cohort, after: after, days: fields[:days]).call }
    succeed "أُزيح الجدول"
  rescue ArgumentError, TypeError, ActiveRecord::RecordInvalid => e
    error e.message
    keep_modal_open
  end

  private

  def parse_date(value)
    year, _, month, day = DATE_FORMAT.match(value)&.captures
    raise ArgumentError, "تاريخ غير صحيح: #{value}" unless year && Date.valid_date?(year.to_i, month.to_i, day.to_i)

    Date.new(year.to_i, month.to_i, day.to_i)
  end
end
