# frozen_string_literal: true

module Api
  class TranscriptionsController < BaseController
    TRANSCRIBABLE_TYPES = %w[Lecture Lesson Fatwa].freeze

    def pending
      limit = (params[:limit] || 20).to_i
      resource_type = params[:type]&.capitalize
      scholar_id = params[:scholar_id]

      results = []

      types_to_query = resource_type.present? && TRANSCRIBABLE_TYPES.include?(resource_type) ?
                       [ resource_type ] : TRANSCRIBABLE_TYPES

      types_to_query.each do |type|
        break if results.size >= limit

        klass = type.constantize
        remaining = limit - results.size

        # Only include items with final_audio (public R2 storage)
        records = klass
          .where(transcription_json: [ nil, "" ])
          .joins(:final_audio_attachment)

        # Filter by scholar_id if provided
        if scholar_id.present?
          records = apply_scholar_filter(records, type, scholar_id)
        end

        records = records.limit(remaining)

        records.each do |record|
          audio_url = build_audio_url(record)
          next unless audio_url

          results << {
            id: record.id,
            type: type,
            title: record.title,
            audio_url: audio_url
          }
        end
      end

      render json: { pending: results, count: results.size }
    end

    def upload
      type = params[:type]&.capitalize
      unless TRANSCRIBABLE_TYPES.include?(type)
        return render json: { error: "Invalid type" }, status: :unprocessable_entity
      end

      record = type.constantize.find(params[:id])

      unless params[:transcription_json].present?
        return render json: { error: "No transcription data provided" }, status: :unprocessable_entity
      end

      # Validate JSON structure
      begin
        parsed = JSON.parse(params[:transcription_json])
        unless parsed.is_a?(Hash) && parsed["segments"].is_a?(Array)
          return render json: { error: "Invalid transcription format" }, status: :unprocessable_entity
        end
      rescue JSON::ParserError
        return render json: { error: "Invalid JSON" }, status: :unprocessable_entity
      end

      record.update!(transcription_json: params[:transcription_json])

      render json: { success: true, id: record.id, type: type }
    end

    private

    def apply_scholar_filter(records, type, scholar_id)
      case type
      when "Lecture"
        records.where(scholar_id: scholar_id)
      when "Lesson"
        records.joins(:series).where(series: { scholar_id: scholar_id })
      when "Fatwa"
        records.where(scholar_id: scholar_id)
      else
        records
      end
    end

    def build_audio_url(record)
      return nil unless record.respond_to?(:final_audio) && record.final_audio.attached?

      # Use the public R2 URL directly
      record.attachment_url(record.final_audio)
    end
  end
end
