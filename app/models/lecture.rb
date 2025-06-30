class Lecture < ApplicationRecord
  validates :title, presence: true, uniqueness: true

  has_one_attached :thumbnail, service: Rails.application.config.public_storage
  has_one_attached :audio, service: Rails.application.config.public_storage
  has_one_attached :video, service: Rails.application.config.public_storage
  has_one_attached :optimized_audio, service: Rails.application.config.public_storage
  has_rich_text :content

  after_save :extract_media_duration
  after_commit :process_media_files, on: [:create, :update]

  attr_accessor :audio_blob_id_before_save, :video_blob_id_before_save

  before_save :cache_blob_ids

  def video?
    video.attached?
  end

  def audio?
    audio.attached?
  end

  private

  def cache_blob_ids
    self.audio_blob_id_before_save = audio.attachment&.blob_id
    self.video_blob_id_before_save = video.attachment&.blob_id
  end

  def process_media_files
    if audio_blob_changed?
      AudioOptimizationJob.perform_later(self)
    end

    if video_blob_changed?
      VideoProcessingJob.perform_later(self)
    end
  end

  def audio_blob_changed?
    audio.attachment&.blob_id != audio_blob_id_before_save
  end

  def video_blob_changed?
    video.attachment&.blob_id != video_blob_id_before_save
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
