class VideoProcessingJob < ApplicationJob
  queue_as :default

  def perform(item)
    return unless item.video?
    return if item.audio.attached? && item.thumbnail.attached?

    video_data = item.video.download
    unique_id  = SecureRandom.hex(10)

    begin
      # === Audio Extraction ===
      unless item.audio.attached?
        Rails.logger.info "Extracting audio for item #{item.id}"

        converter = VideoToAudioConverter.new(StringIO.new(video_data))
        audio_io  = converter.convert

        item.audio.attach(
          io:          audio_io,
          filename:    "audio_#{unique_id}.mp3",
          content_type: "audio/mpeg"
        )

        Rails.logger.info "Attached audio for item #{item.id}"
        AudioOptimizationJob.perform_now(item)
      end

      # === Thumbnail Generation ===
      unless item.thumbnail.attached?
        Rails.logger.info "Generating thumbnail for item #{item.id}"

        thumbnail_io = generate_thumbnail_io(StringIO.new(video_data))

        item.thumbnail.attach(
          io:          thumbnail_io,
          filename:    "thumb_#{item.id}_#{unique_id}.jpg",
          content_type: "image/jpeg"
        )

        Rails.logger.info "Attached thumbnail for item #{item.id}"
      end
    rescue => e
      Rails.logger.error "Video processing failed for item #{item.id}: #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end

  private

  def generate_thumbnail_io(input_io)
    output_io = StringIO.new

    command = %w[
      ffmpeg -loglevel error
      -i - # read from stdin
      -ss 0 # seek to 0 seconds
      -vframes 1 # extract only 1 frame
      -f image2
      -vcodec mjpeg # output as JPEG
      - # write to stdout
    ]

    Open3.popen2(*command) do |stdin, stdout, wait_thr|
      writer = Thread.new { IO.copy_stream(input_io, stdin); stdin.close }
      IO.copy_stream(stdout, output_io)
      writer.join

      raise "Thumbnail generation failed" unless wait_thr.value.success?
    end

    output_io.rewind
    output_io
  rescue => e
    raise "Failed to generate thumbnail: #{e.message}"
  end
end
