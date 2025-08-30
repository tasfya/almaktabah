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

  def generate_optimize_audio_bucket_key
    "all-audios/#{scholar.full_name}/benefits/#{title}.mp3"
  end

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

  def set_duration
    MediaDurationExtractionJob.perform_later(self)
    end
end
