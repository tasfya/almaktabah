class Avo::Resources::Series < Avo::BaseResource
  self.title = :title
  self.includes = [ :scholar ]
  self.search = {
    query: -> { query.ransack(id_eq: params[:q], title_cont: params[:q], description_cont: params[:q], m: "or").result(distinct: false) }
  }
  self.default_view_type = :table
  self.visible_on_sidebar = true

  def filters
    filter Avo::Filters::AutoFilter
    filter Avo::Filters::ScholarFilter
    filter Avo::Filters::PublishedFilter
    filter Avo::Filters::DateRangeFilter
  end

  def fields
    field :id, as: :id, sortable: true
    field :title, as: :text, sortable: true, searchable: true
    field :description, as: :textarea, searchable: true
    field :published, as: :boolean, sortable: true
    field :scholar, as: :belongs_to, sortable: true, searchable: true
    field :explainable, as: :file, accept: "pdf/*", max_size: 5.megabytes
    field :lessons_count, as: :text, only_on: [ :index, :show ], sortable: true
    field :lessons, as: :has_many, searchable: true, use_resource: Avo::Resources::Lesson, show_on: [ :show, :edit ]
    field :created_at, as: :date_time, hide_on: [ :new, :edit ], sortable: true
    field :updated_at, as: :date_time, hide_on: [ :new, :edit ], sortable: true
  end

  def actions
    action Avo::Actions::PublishSeries
    action Avo::Actions::UnpublishSeries
  end
end
