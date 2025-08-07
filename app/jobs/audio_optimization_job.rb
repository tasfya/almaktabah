class AudioOptimizationJob < ApplicationJob
  queue_as :default

  def perform(item)
    return unless item.audio?
    return if item.optimized_audio.attached?

    begin
      item.audio.open do |audio_file|
        input_tempfile = create_input_tempfile(item, audio_file)
        output_tempfile = optimize_audio_to_tempfile(input_tempfile)

        attach_optimized_audio(item, output_tempfile)
        item.save!

        Rails.logger.info "Audio optimization completed for item ID #{item.id}"
      end
    rescue => e
      Rails.logger.error "Audio optimization failed for item ID #{item.id}: #{e.message}"
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
    output_tempfile = Tempfile.new([ "optimized_audio", ".mp3" ])
    output_tempfile.close

    optimizer = AudioOptimizer.new(input_tempfile.path, output_tempfile.path)
    optimizer.optimize

    output_tempfile.open
    output_tempfile
  end

  def attach_optimized_audio(item, output_tempfile)
    output_tempfile.rewind
    key = item.respond_to?(:generate_bucket_key) ? item.generate_bucket_key(prefix: "_op") : "#{item.class.name.underscore}/#{SecureRandom.hex(10)}.mp3"

    item.optimized_audio.attach(
      io: output_tempfile,
      filename: item.audio.filename.to_s,
      key:,
      content_type: "audio/mpeg"
    )
  end
end
