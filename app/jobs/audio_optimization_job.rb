class AudioOptimizationJob < ApplicationJob
  queue_as :ffmpeg_queue

  def perform(item)
    return unless item.audio?
    return if item.final_audio.attached?

    begin
      # Check if audio file actually exists in storage
      unless audio_exists?(item)
        Rails.logger.warn "Audio file missing from storage for #{item.class.name} ID #{item.id}, purging orphaned attachment"
        item.audio.purge
        return
      end

      item.audio.open do |audio_file|
        input_tempfile = create_input_tempfile(item, audio_file)
        output_tempfile = optimize_audio_to_tempfile(input_tempfile)

        # Get original duration BEFORE attaching
        original_duration = extract_duration(input_tempfile.path)

        # Skip if attachment was not created (duplicate key)
        unless attach_final_audio(item, output_tempfile)
          Rails.logger.info "Skipping #{item.class.name} ID #{item.id} - final audio key already exists"
          return
        end

        item.save!

        # Verify and delete original (disabled for now)
        # verify_and_delete_original(item, original_duration)

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
    key = item.generate_final_audio_bucket_key

    # Skip if this key already exists to prevent duplicates
    if ActiveStorage::Blob.exists?(key: key)
      Rails.logger.info "Key #{key} already exists, skipping attachment for #{item.class.name} ID #{item.id}"
      return false
    end

    item.final_audio.attach(
      io: output_tempfile,
      filename: "#{File.basename(item.audio.filename.to_s, '.*')}.mp3",
      key: key,
      content_type: "audio/mpeg"
    )
    true
  end

  def extract_duration(file_path)
    movie = FFMPEG::Movie.new(file_path)
    movie.duration
  rescue => e
    Rails.logger.warn "Failed to extract duration: #{e.message}"
    nil
  end

  def audio_exists?(item)
    return false unless item.audio.attached?

    item.audio.blob.service.exist?(item.audio.blob.key)
  rescue => e
    Rails.logger.warn "Failed to check audio existence for #{item.class.name} ID #{item.id}: #{e.message}"
    false
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
