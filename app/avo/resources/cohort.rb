class Avo::Resources::Cohort < Avo::BaseResource
  self.title = :name
  self.includes = [ :program ]
  self.default_view_type = :table

  def fields
    field :id, as: :id
    field :program, as: :belongs_to, name: "البرنامج", disabled: -> { record&.persisted? }
    field :name, as: :text, name: "الاسم", sortable: true
    field :exam_warning, as: :text, only_on: :index, name: "تنبيه", as_html: true do
      titles = record.exams_without_questions.pluck(:title)
      Avo::WarningMarkup.badge("اختبار بلا أسئلة", title: titles.join("، ")) if titles.any?
    end
    field :exam_warning_detail, as: :text, only_on: :show, name: "تنبيه", as_html: true,
      visible: -> { resource.record.exams_without_questions.exists? } do
      titles = record.exams_without_questions.pluck(:title).map { |title| "«#{title}»" }.join("، ")
      Avo::WarningMarkup.alert("اختبارات بلا أسئلة: #{titles}. لا تُفتح أبدًا، ولا يحصل أي طالب في هذه الدفعة على شهادة حتى تُكتب أسئلتها.")
    end
    field :starts_on, as: :date, name: "تاريخ البداية", sortable: true
    field :time_zone, as: :select, name: "المنطقة الزمنية",
      options: -> { ActiveSupport::TimeZone.all.map { |zone| [ zone.to_s, zone.tzinfo.name ] }.uniq(&:last) },
      default: "Asia/Riyadh"
    field :enrollment_closes_at, as: :date_time, name: "إغلاق التسجيل يدويًا (اختياري)", timezone: -> { record.time_zone },
      help: "اتركه فارغًا ليُغلق التسجيل عند إغلاق أول نافذة اختبار."
    field :enrollment_deadline, as: :date_time, only_on: :show, name: "موعد إغلاق التسجيل المطبَّق", timezone: -> { record.time_zone }
    field :cohort_slots, as: :has_many, translation_key: "avo.resource_translations.cohort_slot", attach_scope: -> { query.none }
    field :enrollments, as: :has_many, translation_key: "avo.resource_translations.enrollment", attach_scope: -> { query.none }
  end

  def actions
    action Avo::Actions::GenerateCohortSchedule
    action Avo::Actions::ShiftCohortSchedule
    action Avo::Actions::ClearCohortSchedule
  end
end
