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
    field :published_date, as: :date
    field :duration, as: :number, step: 1, suffix: "seconds"
    field :category, as: :text
    field :content, as: :trix
    field :video_url, as: :text, link_to: true
    field :youtube_url, as: :text, link_to: true
    field :video, as: :file, accept: "video/*", max_size: 100.megabytes
    field :audio, as: :file
    field :optimized_audio, as: :file, accept: "audio/*", max_size: 10.megabytes
    field :thumbnail, as: :file, accept: "image/*", max_size: 5.megabytes
  end
end
