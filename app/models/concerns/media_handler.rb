module MediaHandler
  extend ActiveSupport::Concern

  included do
    after_commit :process_media_files, on: [ :create, :update ]
  end

  def video?
    video.attached?
  end

  def audio?
    audio.attached?
  end

  private

  def process_media_files
    return unless audio.attached? || video.attached?

    MediaDurationExtractionJob.perform_later(self)
    AudioOptimizationJob.perform_later(self)
    VideoProcessingJob.perform_later(self)
  end

  def handle_youtube_resource
      YoutubeDownloadJob.perform_later("Lesson", lesson.id, "video")
  end
end
