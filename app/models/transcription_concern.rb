module TranscriptionConcern
  extend ActiveSupport::Concern

  included do
    def transcription_segments
      return [] unless transcription_json.present?

      @transcription_segments ||= begin
        parsed = JSON.parse(transcription_json)
        Array(parsed["segments"]).map do |seg|
          {
            start: (seg["start"] || seg[:start] || 0).to_f,
            end:   (seg["end"]   || seg[:end]   || 0).to_f,
            text:  (seg["text"]  || seg[:text]  || "")
          }
        end
      rescue JSON::ParserError
        []
      end
    end
  end
end
