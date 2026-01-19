module TranscriptionConcern
  extend ActiveSupport::Concern

  included do
    # Format seconds into H:MM:SS or M:SS as appropriate.
    def format_timestamp(seconds)
      total = seconds.to_i
      h = total / 3600
      m = (total % 3600) / 60
      s = total % 60
      h.positive? ? "%d:%02d:%02d" % [ h, m, s ] : "%d:%02d" % [ m, s ]
    end

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
