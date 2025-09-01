class Benefit < ApplicationRecord
  include Publishable
  include MediaHandler
  include DomainAssignable

  belongs_to :scholar, optional: true

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage


  has_rich_text :content

  after_commit :set_duration, on: [ :create, :update ]
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 1000 }

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "title", "description", "category", "published", "published_at", "scholar_id", "updated_at", "created_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "scholar" ]
  end

  ##
  # Builds the storage bucket key for the optimized audio file for this benefit.
  # The key is formed from the scholar's full name and the benefit title, e.g.
  # "all-audios/Scholar Name/benefits/Benefit Title.mp3".
  # @return [String] The bucket key for the optimized audio file.
  # @raise [NoMethodError] If `scholar` is nil (the method calls `scholar.full_name`).
  def generate_optimize_audio_bucket_key
    "all-audios/#{scholar.full_name}/benefits/#{title}.mp3"
  end

  ##
  # Returns a JSON-ready Hash representation of the Benefit suitable for API responses.
  #
  # The hash includes top-level attributes (id, title, description, category, published_at, duration),
  # a minimal scholar object ({ id, name }) when a scholar is present, and URLs for attached media
  # (thumbnail_url, audio_url, video_url) only when the corresponding ActiveStorage attachment exists.
  # content_excerpt contains the plain-text content truncated to 200 characters.
  #
  # The optional `options` parameter is accepted for compatibility with callers that pass serialization
  # options but is not used by this implementation.
  #
  # @param [Hash] options - (optional) compatibility parameter; currently ignored.
  # @return [Hash] JSON-serializable representation of the Benefit.
  def as_json(options = {})
    {
      id: id,
      title: title,
      description: description,
      category: category,
      published_at: published_at,
      duration: duration,
      scholar: scholar.present? ? { id: scholar.id, name: scholar.name } : nil,
      thumbnail_url: thumbnail.attached? ? Rails.application.routes.url_helpers.rails_blob_url(thumbnail, only_path: true) : nil,
      audio_url: audio.attached? ? Rails.application.routes.url_helpers.rails_blob_url(audio, only_path: true) : nil,
      video_url: video.attached? ? Rails.application.routes.url_helpers.rails_blob_url(video, only_path: true) : nil,
      content_excerpt: content.to_plain_text.truncate(200)
    }
  end

  private

  ##
    # Enqueues a background job to extract and persist this benefit's media duration.
    # Schedules MediaDurationExtractionJob.perform_later(self) so duration extraction runs asynchronously;
    # intended to be invoked from an after_commit callback (e.g., on create/update).
    def set_duration
    MediaDurationExtractionJob.perform_later(self)
    end
end
