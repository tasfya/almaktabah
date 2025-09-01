class Lecture < ApplicationRecord
  include MediaHandler
  include DomainAssignable
  include Publishable

  enum :kind, { sermon: 1, conference: 2, benefit: 3 }

  validates :title, presence: true
  validates :source_url, uniqueness: true, allow_blank: true

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage
  has_rich_text :content
  belongs_to :scholar

  scope :recent, -> { order(published_at: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "description", "duration", "id", "published", "published_at", "scholar_id", "title", "updated_at" ]
  end
  scope :with_audio, -> { joins(:audio_attachment) }
  scope :without_audio, -> { where.missing(:audio_attachment) }

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

  ##
  # Builds the storage key used for the optimized audio file for this lecture.
  # The returned key follows the format: "all-audios/{scholar.name}/lectures/{kind}/{title}.mp3".
  # @return [String] The generated bucket/key path for the lecture's optimized audio.
  def generate_optimize_audio_bucket_key
    "all-audios/#{scholar.name}/lectures/#{kind}/#{title}.mp3"
  end

  ##
  # Serializes the Lecture to a simple Hash suitable for JSON responses.
  #
  # Returns a hash with core attributes (id, title, description, category, kind, published_at, duration),
  # a nested scholar object (id and name), and media URL fields (thumbnail_url, audio_url, video_url).
  # Media URL values are the Rails blob path (only_path: true) when the corresponding Active Storage
  # attachment is present, otherwise nil.
  # @param [Hash] options (unused) Serialization options (accepted for compatibility but not applied).
  # @return [Hash] A JSON-ready representation of the lecture.
  def as_json(options = {})
    {
      id: id,
      title: title,
      description: description,
      category: category,
      kind: kind,
      published_at: published_at,
      duration: duration,
      scholar: {
        id: scholar.id,
        name: scholar.name
      },
      thumbnail_url: thumbnail.attached? ? Rails.application.routes.url_helpers.rails_blob_url(thumbnail, only_path: true) : nil,
      audio_url: audio.attached? ? Rails.application.routes.url_helpers.rails_blob_url(audio, only_path: true) : nil,
      video_url: video.attached? ? Rails.application.routes.url_helpers.rails_blob_url(video, only_path: true) : nil
    }
  end
end
