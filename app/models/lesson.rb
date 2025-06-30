class Lesson < ApplicationRecord
  belongs_to :series

  validates :title, presence: true, uniqueness: true

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage

  has_rich_text :content

  after_save :extract_media_duration
  after_commit :process_media_files, on: [ :create, :update ]

  # Scopes
  scope :recent, -> { order(published_date: :desc) }
  scope :most_viewed, -> { order(view_count: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_series, ->(series_id) { where(series_id: series_id) if series_id.present? }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "category", "created_at", "description", "duration", "id", "published_date", "series_id", "title", "updated_at", "view_count" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "series" ]
  end

  def video?
    video.attached?
  end

  def media_type
      video? ? "video" : "audio"
  end

  def audio?
    audio.attached?
  end

  def audio_url
    return nil unless audio.attached?
    Rails.application.routes.url_helpers.rails_blob_url(audio, only_path: true)
  end

  def series_title
    series&.title
  end

  private

  def process_media_files
    if video?
      VideoProcessingJob.perform_later(self)
    end

    if audio?
      AudioOptimizationJob.perform_later(self)
    end
  end

  def extract_media_duration
    return unless audio.attached? || video.attached?

    media_file = video.attached? ? video : audio

    media_file.open do |file|
      movie = FFMPEG::Movie.new(file.path)
      update_column(:duration, movie.duration.to_i) if movie.duration
    end
  rescue => e
    Rails.logger.error "Failed to extract duration: #{e.message}"
  end
end
