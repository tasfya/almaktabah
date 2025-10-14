class Avo::Resources::Scholar < Avo::BaseResource
  self.title = :name
  self.search = {
    query: -> { query.ransack(id_eq: params[:q], name_cont: params[:q], bio_cont: params[:q], m: "or").result(distinct: false) }
  }
  self.default_view_type = :table
  self.visible_on_sidebar = true

  def filters
    filter Avo::Filters::AutoFilter
    filter Avo::Filters::DateRangeFilter
  end

  def fields
    field :id, as: :id, sortable: true
    field :name, as: :text, sortable: true, searchable: true
    field :full_name, as: :text, sortable: true, searchable: true
    field :default_domain, as: :belongs_to, searchable: true, sortable: true
    field :bio, as: :textarea, searchable: true
    field :avatar, as: :file, accept: "image/*", max_size: 5.megabytes
    field :lectures_count, as: :text, only_on: [ :index, :show ], sortable: true
    field :series_count, as: :text, only_on: [ :index, :show ], sortable: true
    field :created_at, as: :date_time, hide_on: [ :new, :edit ], sortable: true
    field :updated_at, as: :date_time, hide_on: [ :new, :edit ], sortable: true
  end
end
