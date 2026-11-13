class Avo::Resources::CohortSlot < Avo::BaseResource
  self.title = :id
  self.includes = [ :cohort, :program_item ]
  self.visible_on_sidebar = false
  self.default_sort_column = :available_on
  self.default_sort_direction = :asc

  def fields
    field :id, as: :id, hide_on: :index
    field :cohort, as: :belongs_to, name: "الدفعة"
    field :program_item, as: :belongs_to, name: "العنصر",
      attach_scope: -> { parent.cohort ? query.where(program_id: parent.cohort.program_id) : query.none }
    field :available_on, as: :date, name: "متاح من", sortable: true
    field :opens_at, as: :date_time, name: "يُفتح في", timezone: -> { record.cohort&.time_zone }, help: "للاختبارات فقط"
    field :closes_at, as: :date_time, name: "يُغلق في", timezone: -> { record.cohort&.time_zone }, help: "للاختبارات فقط"
  end
end
