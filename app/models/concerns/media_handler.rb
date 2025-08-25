module MediaHandler
  extend ActiveSupport::Concern
  include ApplicationHelper

  included do
    has_one_attached :thumbnail,       service: Rails.application.config.public_storage
    has_one_attached :audio,           service: Rails.application.config.public_storage
    has_one_attached :video,           service: Rails.application.config.public_storage
    has_one_attached :optimized_audio, service: Rails.application.config.public_storage

    after_save :process_media_files
    after_commit :set_duration, on: [ :create, :update ]
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

  def generate_bucket_key(prefix: nil, attachment_name: nil, extension: nil)
    key = ""
    scholar_slug = scholar&.name ? slugify_arabic(scholar.name) : "unknown-scholar"

    case self.class.name
    when "Lesson"
      series_slug = slugify_arabic(series.title)
      name = position ? position.to_s : slugify_arabic(title)
      key = "scholars/#{scholar_slug}/series/#{series_slug}/#{name}"
    when "Lecture"
      slug = slugify_arabic(title)
      key = "scholars/#{scholar_slug}/lectures/#{slug}"
    when "Benefit"
      slug = slugify_arabic(title)
      key = "scholars/#{scholar_slug}/benefits/#{slug}"
    end

    if prefix
      key += "#{prefix}"
    end

    "#{key}#{extension}"
  end

  private

  def process_media_files
    # return unless audio.attached? || video.attached?

    AudioOptimizationJob.perform_later(self)
    # VideoProcessingJob.perform_later(self)

    # handle_youtube_resource
  end

  def handle_youtube_resource
    return unless self.respond_to?(:youtube_url) && youtube_url.present? && !video.attached?
    YoutubeDownloadJob.perform_later(self, file_url: youtube_url)
  end

  def set_duration
    MediaDurationExtractionJob.perform_later(self)
  end
end
