# frozen_string_literal: true

require "down"

class MimhamAudioDownloadJob < ApplicationJob
  queue_as :default

  retry_on Down::Error, wait: :polynomially_longer, attempts: 3
  retry_on Down::TimeoutError, wait: 1.minute, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(record_type, record_id, audio_url)
    record = record_type.constantize.find(record_id)

    return if record.audio.attached?
    return if audio_url.blank?

    Rails.logger.info "[MimhamAudioDownload] Downloading audio for #{record_type}##{record_id}: #{audio_url}"

    tempfile = Down.download(
      audio_url,
      max_size: 500 * 1024 * 1024, # 500MB max
      read_timeout: 300, # 5 minutes
      open_timeout: 30
    )

    filename = generate_filename(record, audio_url)

    record.audio.attach(
      io: tempfile,
      filename: filename,
      content_type: "audio/mpeg"
    )

    Rails.logger.info "[MimhamAudioDownload] Successfully attached audio to #{record_type}##{record_id}"
  rescue Down::NotFound
    Rails.logger.warn "[MimhamAudioDownload] Audio not found (404): #{audio_url}"
  rescue => e
    Rails.logger.error "[MimhamAudioDownload] Failed for #{record_type}##{record_id}: #{e.message}"
    raise
  ensure
    if tempfile
      tempfile.close
      tempfile.unlink if tempfile.respond_to?(:unlink)
    end
  end

  private

  def generate_filename(record, url)
    base = case record
    when Lesson
      "#{record.position || record.id}"
    when Lecture
      record.title.parameterize.presence || record.id.to_s
    else
      record.id.to_s
    end

    extension = File.extname(URI.parse(url).path).presence || ".mp3"
    "#{base}#{extension}"
  end
end
