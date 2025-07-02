module MediaHandler
  extend ActiveSupport::Concern

  included do
    attr_accessor :audio_blob_id_before_save, :video_blob_id_before_save

    before_save :cache_media_blob_ids
    after_commit :process_media_files, on: [ :create, :update ]
  end

  def video?
    video.attached?
  end

  def audio?
    audio.attached?
  end

  def audio_blob_changed?
    audio.attachment&.blob_id != audio_blob_id_before_save
  end

  def video_blob_changed?
    video.attachment&.blob_id != video_blob_id_before_save
  end

  def media_files_changed?
    audio_blob_changed? || video_blob_changed?
  end

  private

  def process_media_files
    return unless audio.attached? || video.attached?
    return unless media_files_changed?

    # Extract duration asynchronously
    MediaDurationExtractionJob.perform_later(self)

    # Process audio if changed
    if audio_blob_changed?
      AudioOptimizationJob.perform_later(self)
    end

    # Process video if changed
    if video_blob_changed?
      VideoProcessingJob.perform_later(self)
    end
  end

  def cache_media_blob_ids
    self.audio_blob_id_before_save = audio.attachment&.blob_id
    self.video_blob_id_before_save = video.attachment&.blob_id
  end
end
