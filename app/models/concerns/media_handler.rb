module MediaHandler
  extend ActiveSupport::Concern

  included do
    after_save :process_media_files
  end

  def video?
    video.attached?
  end

  def audio?
    audio.attached?
  end

  def optimized_audio?
    optimized_audio.attached?
  end

  def media_type
    if video?
      I18n.t("common.video")
    elsif audio?
      I18n.t("common.audio")
    else
      nil
    end
  end

  private

  def process_media_files
    # return unless audio.attached? || video.attached?

    # AudioOptimizationJob.perform_later(self)
    # VideoProcessingJob.perform_later(self)

    # handle_youtube_resource
  end

  def handle_youtube_resource
    return unless self.respond_to?(:youtube_url) && youtube_url.present? && !video.attached?
    YoutubeDownloadJob.perform_later(self, file_url: youtube_url)
  end
end
