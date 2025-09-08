class Lecture < ApplicationRecord
  include Sluggable
  include MediaHandler
  include DomainAssignable
  include Publishable
  include AudioFallback
  include AttachmentSerializable

  enum :kind, { sermon: 1, conference: 2, benefit: 3 }

  validates :title, presence: true
  validates :source_url, uniqueness: true, allow_blank: true

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage
  has_rich_text :content
  belongs_to :scholar, inverse_of: :lectures

  scope :recent, -> { order(published_at: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :with_audio, -> { joins(:audio_attachment) }
  scope :without_audio, -> { where.missing(:audio_attachment) }


  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "description", "duration", "id", "published", "published_at", "scholar_id", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "scholar" ]
  end

  def podcast_title
    title
  end

  def audio_file_size
    return nil unless audio.attached?

    audio.blob.byte_size
  end

  def summary
    description
  end

  def audio_url
    return nil unless audio.attached?

    Rails.application.routes.url_helpers.rails_blob_url(audio, only_path: true)
  end

  def generate_optimize_audio_bucket_key
    "all-audios/#{scholar.name}/lectures/#{kind}/#{title}.mp3"
  end

  def as_json(options = {})
    {
      id: id,
      title: title,
      description: description,
      category: category,
      kind: kind,
      published_at: published_at,
      duration: duration,
      scholar: scholar.as_json,
      thumbnail_url: attachment_url(thumbnail),
      audio_url: attachment_url(audio),
      video_url: attachment_url(video)
    }
  end
end
