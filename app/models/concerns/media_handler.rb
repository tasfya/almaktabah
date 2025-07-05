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
    # return unless audio.attached? || video.attached?

    # AudioOptimizationJob.perform_later(self)
    # VideoProcessingJob.perform_later(self)

    # handle_youtube_resource if youtube_url.present? && !video.attached?
  end

  def handle_youtube_resource
    YoutubeDownloadJob.perform_later(self, file_url: youtube_url)
  end
end
