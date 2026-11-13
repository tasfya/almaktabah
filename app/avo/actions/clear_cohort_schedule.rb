class Avo::Actions::ClearCohortSchedule < Avo::BaseAction
  self.name = "مسح الجدول"
  self.message = "يمسح كل مواعيد الدفعة. يُرفض إذا سجّل طالب تقدّمًا (درسًا أو اختبارًا)."

  def handle(records:, **)
    refused = records.reject(&:clear_schedule!)
    return succeed("مُسح الجدول") if refused.empty?

    error refused.map { |cohort| "#{cohort.name}: #{cohort.errors.full_messages.to_sentence}" }.join("\n")
    keep_modal_open
  end
end
