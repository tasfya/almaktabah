class AudioTranscriptionJob < ApplicationJob
  queue_as :default

  def perform(record)
    return unless record.present?
    return unless record.respond_to?(:audio) && record.audio.attached?
    return if record.respond_to?(:transcription_json) && record.transcription_json.present?

    Rails.logger.info "Starting audio transcription for #{record.class.name}##{record.id}"

    begin
      service = AudioTranscriptionService.new(record)
      service.transcribe!

      Rails.logger.info "Successfully transcribed audio for #{record.class.name}##{record.id}"
    rescue => e
      Rails.logger.error "Failed to transcribe audio for #{record.class.name}##{record.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end
