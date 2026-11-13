class Avo::Resources::Cohort < Avo::BaseResource
  self.title = :name
  self.includes = [ :program ]
  self.default_view_type = :table

  def fields
    field :id, as: :id
    field :program, as: :belongs_to
    field :name, as: :text, sortable: true
    field :starts_on, as: :date, sortable: true
    field :time_zone, as: :select, options: -> { ActiveSupport::TimeZone.all.map { |zone| [ zone.to_s, zone.tzinfo.name ] }.uniq(&:last) },
      default: "Asia/Riyadh"
    field :enrollment_closes_at, as: :date_time, timezone: -> { record.time_zone },
      help: "Optional override. By default enrollment closes when the first exam window closes."
    field :enrollment_deadline, as: :date_time, only_on: :show, timezone: -> { record.time_zone }
    field :cohort_slots, as: :has_many, name: "Schedule"
    field :enrollments, as: :has_many
  end

  def actions
    action Avo::Actions::GenerateCohortSchedule
    action Avo::Actions::ShiftCohortSchedule
  end
end
