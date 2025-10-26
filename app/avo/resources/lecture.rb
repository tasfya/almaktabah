class Avo::Resources::Lecture < Avo::BaseResource
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
    filter Avo::Filters::CategoryFilter
    filter Avo::Filters::DateRangeFilter
  end

  def fields
    field :id, as: :id, sortable: true
    field :title, as: :text, sortable: true, searchable: true
    field :description, as: :textarea, searchable: true
    field :category, as: :text, sortable: true, searchable: true
    field :content, as: :trix
    field :published, as: :boolean, sortable: true
    field :scholar, as: :belongs_to, attach_scope: -> {
      query.joins(:users).where(users: { id: Avo::Current.user.id }).limit(50)
    }
    field :kind, as: :select, enum: Lecture.kinds, sortable: true
    field :youtube_url, as: :text, help: "YouTube URL for video lessons"
    field :video_url, as: :text, help: "URL for video lessons"
    field :published_at, as: :date_time, help: "The date and time when this lecture was published", hide_on: [ :new, :edit ], sortable: true
    field :thumbnail, as: :file, accept: "image/*", max_size: 5.megabytes
    field :audio, as: :file, accept: "audio/*", max_size: 10.megabytes
    field :video, as: :file, accept: "video/*", max_size: 100.megabytes
    field :generated_video, as: :file, accept: "video/*", max_size: 100.megabytes, hide_on: [ :new, :edit ], readonly: true
    field :optimized_audio, as: :file, accept: "audio/*", max_size: 10.megabytes, hide_on: [ :new, :edit ], readonly: true
    field :created_at, as: :date_time, hide_on: [ :new, :edit ], sortable: true
    field :updated_at, as: :date_time, hide_on: [ :new, :edit ], sortable: true
  end

  def actions
    action Avo::Actions::GenerateVideo
    action Avo::Actions::PublishLecture
    action Avo::Actions::UnpublishLecture
  end
end
