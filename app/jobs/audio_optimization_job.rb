class AudioOptimizationJob < ApplicationJob
  queue_as :ffmpeg_queue

  def perform(item)
    return unless item.audio?
    return if item.final_audio.attached?

    begin
      item.audio.open do |audio_file|
        input_tempfile = create_input_tempfile(item, audio_file)
        output_tempfile = optimize_audio_to_tempfile(input_tempfile)

        # Get original duration BEFORE attaching
        original_duration = extract_duration(input_tempfile.path)

        attach_final_audio(item, output_tempfile)
        item.save!

        # Verify and delete original
        verify_and_delete_original(item, original_duration)

        Rails.logger.info "Audio optimization completed for #{item.class.name} ID #{item.id}"
      end
    rescue => e
      Rails.logger.error "Audio optimization failed for #{item.class.name} ID #{item.id}: #{e.message}"
      raise e
    end
  end

  private

  def create_input_tempfile(item, audio_file)
    extension = File.extname(item.audio.filename.to_s)

    tempfile = Tempfile.new([
      "#{item.class.name.underscore}_#{item.id}_input",
      extension
    ])

    tempfile.binmode
    tempfile.write(audio_file.read)
    tempfile.rewind
    tempfile
  end

  def optimize_audio_to_tempfile(input_tempfile)
    output_tempfile = Tempfile.new([ "final_audio", ".mp3" ])
    output_tempfile.close

    optimizer = AudioOptimizer.new(input_tempfile.path, output_tempfile.path)
    optimizer.optimize

    output_tempfile.open
    output_tempfile
  end

  def attach_final_audio(item, output_tempfile)
    output_tempfile.rewind
    key = ensure_key_unique(item)
    item.final_audio.attach(
      io: output_tempfile,
      filename: "#{File.basename(item.audio.filename.to_s, '.*')}.mp3",
      key:,
      content_type: "audio/mpeg"
    )
  end

  def ensure_key_unique(item)
    key = item.generate_final_audio_bucket_key
    counter = 0
    while ActiveStorage::Blob.where(key: key).exists?
      key = "#{key.split('.').first}_#{counter}.mp3"
      counter += 1
      break if counter > 5
    end
    key
  end

  def extract_duration(file_path)
    movie = FFMPEG::Movie.new(file_path)
    movie.duration
  rescue => e
    Rails.logger.warn "Failed to extract duration: #{e.message}"
    nil
  end

  def verify_and_delete_original(item, original_duration)
    return unless original_duration
    return unless item.final_audio.attached?

    # Download final_audio to temp file to verify duration
    item.final_audio.open do |final_file|
      final_duration = extract_duration(final_file.path)

      return unless final_duration

      # Allow 1 second tolerance for encoding differences
      duration_diff = (original_duration - final_duration).abs

      if duration_diff <= 1.0
        Rails.logger.info "Duration verified (diff: #{duration_diff.round(2)}s). Deleting original audio for #{item.class.name} ID #{item.id}."
        item.audio.purge
      else
        Rails.logger.warn "Duration mismatch! Original: #{original_duration}s, Final: #{final_duration}s. Keeping original for #{item.class.name} ID #{item.id}."
      end
    end
  rescue => e
    Rails.logger.error "Failed to verify/delete original audio for #{item.class.name} ID #{item.id}: #{e.message}"
  end
end
