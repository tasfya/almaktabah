class Avo::Resources::Cohort < Avo::BaseResource
  self.title = :name
  self.includes = [ :program ]
  self.default_view_type = :table

  def fields
    field :id, as: :id
    field :program, as: :belongs_to, disabled: -> { record&.persisted? }
    field :name, as: :text, sortable: true
    field :starts_on, as: :date, sortable: true
    field :time_zone, as: :select, options: -> { ActiveSupport::TimeZone.all.map { |zone| [ zone.to_s, zone.tzinfo.name ] }.uniq(&:last) },
      default: "Asia/Riyadh"
    field :enrollment_closes_at, as: :date_time, timezone: -> { record.time_zone },
      help: "Optional override. By default enrollment closes when the first exam window closes."
    field :enrollment_deadline, as: :date_time, only_on: :show, timezone: -> { record.time_zone }
    field :exam_warning, as: :text, only_on: %i[index show], name: "Warning",
      help: "Exams scheduled in this cohort that have no questions yet: they never open and block every certificate." do
      titles = record.exams_without_questions.pluck(:title)
      "No questions yet: #{titles.join(", ")}" if titles.any?
    end
    field :cohort_slots, as: :has_many, name: "Schedule", attach_scope: -> { query.none }
    field :enrollments, as: :has_many, attach_scope: -> { query.none }
  end

  def actions
    action Avo::Actions::GenerateCohortSchedule
    action Avo::Actions::ShiftCohortSchedule
    action Avo::Actions::ClearCohortSchedule
  end
end
