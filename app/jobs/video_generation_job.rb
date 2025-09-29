class VideoGenerationJob < ApplicationJob
  queue_as :default

  def perform(record)
    return unless record.respond_to?(:audio?) && record.audio?
    return if record.respond_to?(:generated_video?) && record.generated_video?

    Rails.logger.info "Starting video generation for #{record.class.name} ##{record.id}"

    begin
      domain = record.respond_to?(:domains) && record.domains.any? ? record.domains.first : nil
      logo = domain&.logo&.attached? ? domain.logo : nil
      logo_file = logo || Rails.root.join("app/assets/images/logo.png")

      service = VideoGeneratorService.new(
        title: record.title,
        description: record.respond_to?(:description) ? record.description : nil,
        audio_file: record.audio,
        logo_file: logo_file
      )

      result = service.call

      if result[:success]
        record.generated_video.attach(
          io: File.open(result[:video_path]),
          filename: result[:filename],
          content_type: "video/mp4"
        )

        Rails.logger.info "Successfully generated video for #{record.class.name} ##{record.id}"

        service.cleanup!
      else
        Rails.logger.error "Video generation failed for #{record.class.name} ##{record.id}: #{result[:error]}"
        raise StandardError, result[:error]
      end

    rescue => e
      Rails.logger.error "Video generation job failed for #{record.class.name} ##{record.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end
