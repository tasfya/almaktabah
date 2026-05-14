# frozen_string_literal: true

module Api
  class TranscriptionsController < BaseController
    TRANSCRIBABLE_TYPES = %w[Lecture Lesson Fatwa].freeze

    def pending
      limit = (params[:limit] || 20).to_i
      resource_type = params[:type]&.capitalize

      results = []

      types_to_query = resource_type.present? && TRANSCRIBABLE_TYPES.include?(resource_type) ?
                       [ resource_type ] : TRANSCRIBABLE_TYPES

      types_to_query.each do |type|
        break if results.size >= limit

        klass = type.constantize
        remaining = limit - results.size

        records = klass
          .where(transcription_json: [ nil, "" ])
          .where.not(id: klass.where.missing(:audio_attachment).select(:id))
          .select(:id, :title)
          .limit(remaining)

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

    def build_audio_url(record)
      return nil unless record.respond_to?(:audio) && record.audio.attached?

      Rails.application.routes.url_helpers.rails_blob_url(
        record.audio,
        host: request.host_with_port,
        protocol: request.protocol.delete("://")
      )
    end
  end
end
