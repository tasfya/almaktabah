require "httparty"
require "json"

class AudioTranscriptionService
  GROQ_API_BASE_URL = "https://api.groq.com/openai/v1".freeze
  GROQ_DEFAULT_MODEL = "whisper-large-v3-turbo".freeze

  def initialize(record: nil, language: "ar")
    @record = record
    @language = language
  end

  def transcribe!
    return unless @record.audio_url.present?

    transcript_json = transcribe_with_groq!(@record.audio_url)
    raise "No transcript generated for #{@record.class.name}##{@record.id}" if transcript_json.blank?

    attach_transcript_to_record(transcript_json)

    transcript_json
  end

  def transcribe_with_groq!(audio_url)
    Rails.logger.info "Transcribing with Groq API for #{@record.class.name}##{@record.id}: #{@record.audio_url}"

    # Build multipart form data body matching the curl example
    body = {
      model: GROQ_DEFAULT_MODEL,
      url: audio_url,
      language: @language,
      temperature: 0,
      response_format: "verbose_json"
    }

    response = HTTParty.post(
      "#{GROQ_API_BASE_URL}/audio/transcriptions",
      headers: {
        "Authorization" => "Bearer #{ENV["GROQ_API_KEY"]}"
      },
      body: body,
      multipart: true,
      timeout: 300 # 5 minutes timeout for large files
    )

    unless response.success?
      error_message = response.parsed_response&.dig("error", "message") || response.body
      Rails.logger.error "Groq API error: #{error_message}"
      raise "Groq API transcription failed: #{error_message}"
    end

    transcript_json = response.parsed_response
    text_length = transcript_json&.dig("text")&.length || 0
    Rails.logger.info "Groq transcription completed: #{text_length} characters, #{transcript_json&.dig("segments")&.length || 0} segments"

    transcript_json.to_json
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse Groq API response: #{e.message}"
    raise "Failed to parse Groq API response: #{e.message}"
  rescue => e
    Rails.logger.error "Error during Groq transcription: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  def attach_transcript_to_record(transcript_json)
    # Store the JSON response in the transcription_json field
    if @record.respond_to?(:transcription_json=)
      @record.transcription_json = transcript_json
      @record.save!
    else
      Rails.logger.warn "#{@record.class.name} does not have transcription_json field. Skipping storage."
    end
  end
end
