class Avo::Resources::Fatwa < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :scholar, as: :belongs_to
    field :title, as: :text
    field :category, as: :text
    field :question, as: :trix
    field :answer, as: :trix
    field :published, as: :boolean
    field :published_at, as: :date_time, help: "The date and time when this fatwa was published", hide_on: [ :new, :edit ]
    field :audio, as: :file, accept: "audio/*", max_size: 10.megabytes
    field :video, as: :file, accept: "video/*", max_size: 100.megabytes
    field :generated_video, as: :file, accept: "video/*", max_size: 100.megabytes, hide_on: [ :new, :edit ], readonly: true
    field :optimized_audio, as: :file, accept: "audio/*", max_size: 10.megabytes, hide_on: [ :new, :edit ], readonly: true
  end

  def actions
    action Avo::Actions::GenerateVideo
  end
end
