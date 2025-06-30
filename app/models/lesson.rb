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

  def video?
    video.attached?
  end

  def audio?
    audio.attached?
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
