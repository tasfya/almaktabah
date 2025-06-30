class Avo::Resources::Lecture < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :title, as: :text
    field :description, as: :textarea
    field :category, as: :text
    field :content, as: :trix
    field :published_date, as: :date
    field :thumbnail, as: :file, accept: "image/*", max_size: 5.megabytes
    field :audio, as: :file, accept: "audio/*", max_size: 10.megabytes
    field :video, as: :file, accept: "video/*", max_size: 100.megabytes
    field :yotube_url, as: :text, help: "YouTube URL for video lessons"
    field :video_url, as: :text, help: "URL for video lessons"
  end
end
