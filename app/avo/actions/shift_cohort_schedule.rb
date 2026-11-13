class Avo::Actions::ShiftCohortSchedule < Avo::BaseAction
  self.name = "إزاحة الجدول"
  self.message = "ينقل كل موعد يبدأ في هذا التاريخ أو بعده بعدد الأيام المحدد (للإجازات). تتغير تواريخ الطلاب المسجلين."

  # Avo's date picker posts YYYY/MM/DD, in the browser locale's digits
  # (Arabic-Indic in an Arabic locale); ISO YYYY-MM-DD is accepted too.
  DATE_FORMAT = %r{\A(\d{4})([/-])(\d{2})\2(\d{2})\z}

  class Refused < StandardError; end

  def fields
    field :after, as: :date, name: "من تاريخ", required: true
    field :days, as: :number, name: "عدد الأيام", required: true, help: "قيمة سالبة تقدّم المواعيد"
  end

  def handle(records:, fields:, **)
    raise ArgumentError, "«من تاريخ» مطلوب" if fields[:after].blank?

    after = parse_date(fields[:after].to_s.tr("٠-٩۰-۹", "0-90-9"))
    CohortSlot.transaction do
      closed = records.select do |cohort|
        live = cohort.exam_slots.where(closes_at: Time.current..).pluck(:id)
        Programs::ScheduleShifter.new(cohort, after: after, days: fields[:days]).call
        cohort.cohort_slots.where(id: live, closes_at: ..Time.current).exists?
      end
      raise Refused, closed.map { |cohort| "#{cohort.name}: الإزاحة تُغلق نافذة اختبار مفتوحة أو قادمة قبل الآن، فيفوت الاختبارُ الطلاب. تحقّق من عدد الأيام." }.join("\n") if closed.any?
    end
    succeed "أُزيح الجدول"
  rescue Refused, ArgumentError, TypeError, ActiveRecord::RecordInvalid => e
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
