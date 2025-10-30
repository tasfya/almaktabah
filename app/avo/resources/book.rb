class Avo::Resources::Book < Avo::BaseResource
  self.title = :title
  self.includes = [ :scholar ]
  self.search = {
    query: -> { query.ransack(id_eq: params[:q], title_cont: params[:q], description_cont: params[:q], m: "or").result(distinct: false) }
  }
  self.default_view_type = :table
  self.visible_on_sidebar = true

  def filters
    filter Avo::Filters::AutoFilter
    filter Avo::Filters::PublishedFilter
    filter Avo::Filters::CategoryFilter
    filter Avo::Filters::DateRangeFilter
  end

  def fields
    field :id, as: :id, sortable: true
    field :title, as: :text, sortable: true, searchable: true
    field :description, as: :text, searchable: true
    field :category, as: :text, sortable: true, searchable: true
    field :published, as: :boolean, sortable: true
    field :published_at, as: :date_time, help: "The date and time when this book was published", hide_on: [ :new, :edit ], sortable: true
    field :downloads, as: :number, sortable: true
    field :file, as: :file
    field :cover_image, as: :file
    field :scholar, as: :belongs_to, attach_scope: -> {
      query.joins(:users).where(users: { id: Avo::Current.user.id }).limit(50)
    }
    field :created_at, as: :date_time, hide_on: [ :new, :edit ], sortable: true
    field :updated_at, as: :date_time, hide_on: [ :new, :edit ], sortable: true
  end

  def actions
    action Avo::Actions::PublishBook
    action Avo::Actions::UnpublishBook
  end
end
