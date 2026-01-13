require "httparty"
require "json"

class AudioTranscriptionService
  GROQ_API_BASE_URL = "https://api.groq.com/openai/v1".freeze
  GROQ_DEFAULT_MODEL = "whisper-large-v3-turbo".freeze

  def initialize(record, language: "ar")
    @record = record
    @language = language
  end

  def transcribe!
    return unless audio_attachment

    audio_url = get_audio_url
    raise "Could not get public URL for audio attachment" unless audio_url.present?

    transcript_json = transcribe_with_groq!(audio_url)
    raise "No transcript generated for #{@record.class.name}##{@record.id}" if transcript_json.blank?

    attach_transcript_to_record(transcript_json)

    transcript_json
  end

  private

  def groq_api_key
    ENV["GROQ_API_KEY"]
  end

  def audio_attachment
    return @audio_attachment if defined?(@audio_attachment)

    if @record.respond_to?(:best_audio)
      @audio_attachment = @record.best_audio
    elsif @record.respond_to?(:audio) && @record.audio.attached?
      @audio_attachment = @record.audio
    else
      @audio_attachment = nil
    end
  end

  def get_audio_url
    @record.audio_url
  end

  def transcribe_with_groq!(audio_url)
    api_key = groq_api_key
    raise "Groq API key not configured. Set GROQ_API_KEY environment variable" unless api_key.present?

    Rails.logger.info "Transcribing with Groq API for #{@record.class.name}##{@record.id}: #{audio_url}"

    # Build multipart form data body matching the curl example
    body = {
      model: GROQ_DEFAULT_MODEL,
      url: audio_url,
      temperature: 0,
      response_format: "verbose_json"
    }

    # TODO: Add timestamp_granularities support if needed
    # Arrays in multipart need special handling: timestamp_granularities[]=segment&timestamp_granularities[]=word

    response = HTTParty.post(
      "#{GROQ_API_BASE_URL}/audio/transcriptions",
      headers: {
        "Authorization" => "Bearer #{api_key}"
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
