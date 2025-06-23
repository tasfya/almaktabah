class Lesson < ApplicationRecord
    belongs_to :series
    validates :title, presence: true, uniqueness: true
    validates :old_id, uniqueness: true, allow_nil: true
    validates :published_date, presence: true
    validates :category, presence: true
    validates :duration, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

    has_one_attached :audio, service: Rails.application.config.public_storage
    has_one_attached :thumbnail, service: Rails.application.config.public_storage
    has_one_attached :video, service: Rails.application.config.public_storage
    has_rich_text :content

    def video?
      video_url.present? || youtube_url.present?
    end

    def audio?
      audio.attached?
    end

    def youtube_video?
      youtube_url.present?
    end

    def series_title
      series&.title
    end

    # Queue YouTube download job
    def download_youtube_video(download_type: "video")
      return false unless youtube_url.present?

      YoutubeDownloadJob.perform_now("Lesson", id, download_type)
      true
    end

    def download_youtube_audio
      return false unless youtube_url.present?
      YoutubeDownloadJob.perform_now("Lesson", id, "audio")
      true
    end

    # Helper method to check if YouTube URL is valid
    def valid_youtube_url?
      return false unless youtube_url.present?
      youtube_url.include?("youtube.com") || youtube_url.include?("youtu.be")
    end
end
