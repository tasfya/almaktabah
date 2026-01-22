class AudioTranscriptionJob < ApplicationJob
  queue_as :low

  def perform(record)
    Rails.logger.info "Starting audio transcription for #{record.class.name}##{record.id}"

    begin
      service = AudioTranscriptionService.new(record: record, language: "ar")
      service.transcribe!

      Rails.logger.info "Successfully transcribed audio for #{record.class.name}##{record.id}"
    rescue => e
      Rails.logger.error "Failed to transcribe audio for #{record.class.name}##{record.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end
