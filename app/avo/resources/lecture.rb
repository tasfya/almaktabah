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
    field :duration, as: :number
    field :category, as: :text
    field :views, as: :number
    field :content, as: :trix
    field :video_url, as: :text, link_to: true
    field :video, as: :file, accept: "video/*", max_size: 100.megabytes
    field :audio, as: :file
    field :thumbnail, as: :file, accept: "image/*", max_size: 5.megabytes
    field :published_date, as: :date
  end
end
