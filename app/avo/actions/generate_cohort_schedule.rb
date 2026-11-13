class Avo::Actions::GenerateCohortSchedule < Avo::BaseAction
  self.name = "توليد الجدول"
  self.message = "يستبدل كل مواعيد الدفعة بمواعيد محسوبة من هذه القاعدة، فتتغير تواريخ الطلاب المسجلين. " \
    "يُرفض إذا سجّل طالب تقدّمًا (درسًا أو اختبارًا) أو إذا كانت نافذة اختبار ستُغلق قبل الآن."

  WEEKDAYS = -> { I18n.t("date.day_names", locale: :ar).each_with_index.to_h { |name, wday| [ name, wday.to_s ] } }

  class Refused < StandardError; end

  def fields
    field :weekdays, as: :select, multiple: true, options: WEEKDAYS, default: %w[0 1 2 3 4 6], name: "أيام الدروس",
      help: "الأيام التي تُنشر فيها الدروس. لاختيار أكثر من يوم اضغط Ctrl (أو Cmd على ماك) مع النقر."
    field :lessons_per_day, as: :number, default: 1, min: 1, name: "دروس في اليوم"
    field :exam_open_wday, as: :select, options: WEEKDAYS, default: "3", name: "يوم فتح الاختبار",
      help: "يُفتح الاختبار في أول يوم من هذا النوع بعد آخر درس يسبقه (قد يكون اليوم التالي له)."
    field :exam_close_wday, as: :select, options: WEEKDAYS, default: "5", name: "يوم إغلاق الاختبار",
      help: "يُغلق الاختبار في أول يوم من هذا النوع ابتداءً من يوم فتحه."
    field :exam_close_hour, as: :number, default: 22, min: 0, max: 23, name: "ساعة الإغلاق",
      help: "الساعة التي يُغلق فيها الاختبار، بتوقيت الدفعة"
    field :skip_ranges, as: :textarea, name: "الإجازات", help: "إجازة في كل سطر: YYYY-MM-DD..YYYY-MM-DD"
  end

  def handle(records:, fields:, **)
    started = records.select(&:learner_progress?)
    raise Refused, started.map { |cohort| "#{cohort.name}: لا يمكن توليد الجدول، طلاب هذه الدفعة سجّلوا تقدّمًا (دروس أو اختبارات)" }.join("\n") if started.any?

    options = {
      weekdays: Array(fields[:weekdays]).compact_blank,
      lessons_per_day: fields[:lessons_per_day],
      exam_open_wday: fields[:exam_open_wday],
      exam_close_wday: fields[:exam_close_wday],
      exam_close_hour: fields[:exam_close_hour],
      skip_ranges: skip_ranges(fields[:skip_ranges])
    }
    CohortSlot.transaction do
      closed = records.select do |cohort|
        Programs::ScheduleGenerator.new(cohort, **options).call
        cohort.exam_slots.where(closes_at: ..Time.current).exists?
      end
      raise Refused, closed.map { |cohort| "#{cohort.name}: نافذة اختبار ستكون مغلقة قبل الآن، فيفوت الاختبارُ كلَّ الطلاب. أخّر تاريخ بداية الدفعة." }.join("\n") if closed.any?
    end
    succeed "وُلّد الجدول"
  rescue Refused, ArgumentError, TypeError, ActiveRecord::RecordInvalid => e
    error e.message
    keep_modal_open
  end

  private

  def skip_ranges(text)
    text.to_s.lines.map(&:strip).compact_blank.map do |line|
      first, last = line.split("..", 2).map(&:strip)
      raise ArgumentError, "إجازة غير صحيحة «#{line}»: اكتبها YYYY-MM-DD..YYYY-MM-DD" if first.blank? || last.blank?

      range = Date.iso8601(first)..Date.iso8601(last)
      raise ArgumentError, "الإجازة «#{line}» تنتهي قبل أن تبدأ" if range.end < range.begin

      range
    rescue Date::Error
      raise ArgumentError, "تاريخ غير صحيح في الإجازة «#{line}»"
    end
  end
end
