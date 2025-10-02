class Avo::Resources::Fatwa < Avo::BaseResource
  self.title = :title
  self.includes = [ :scholar ]
  self.search = {
    query: -> { query.ransack(id_eq: params[:q], title_cont: params[:q], category_cont: params[:q], m: "or").result(distinct: false) }
  }
  self.default_view_type = :table
  self.visible_on_sidebar = true

  def filters
    filter Avo::Filters::AutoFilter
    filter Avo::Filters::ScholarFilter
    filter Avo::Filters::PublishedFilter
    filter Avo::Filters::CategoryFilter
    filter Avo::Filters::DateRangeFilter
  end

  def fields
    field :id, as: :id, sortable: true
    field :title, as: :text, sortable: true, searchable: true
    field :category, as: :text, sortable: true, searchable: true
    field :question, as: :trix
    field :answer, as: :trix
    field :published, as: :boolean, sortable: true
    field :scholar, as: :belongs_to, sortable: true, searchable: true
    field :published_at, as: :date_time, help: "The date and time when this fatwa was published", hide_on: [ :new, :edit ], sortable: true
    field :audio, as: :file, accept: "audio/*", max_size: 10.megabytes
    field :video, as: :file, accept: "video/*", max_size: 100.megabytes
    field :source_url, as: :text, help: "Source URL for the fatwa"
    field :optimized_audio, as: :file, accept: "audio/*", max_size: 10.megabytes, hide_on: [ :new, :edit ], readonly: true
    field :created_at, as: :date_time, hide_on: [ :new, :edit ], sortable: true
    field :updated_at, as: :date_time, hide_on: [ :new, :edit ], sortable: true
  end

  def actions
    action Avo::Actions::GenerateVideo
  end
end
