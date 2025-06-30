class VideoToAudioConverter
  def initialize(input_path, output_path = nil)
    @input_path = input_path.to_s
    @output_path = (output_path || default_output_path).to_s
  end

  def convert
    movie = FFMPEG::Movie.new(@input_path)
    puts "Converting video to optimized MP3: #{@input_path} -> #{@output_path}"

    options = {
      audio_codec: "libmp3lame",
      audio_bitrate: "128k",
      audio_sample_rate: 44100,
      audio_channels: 2,
      custom: %w[-vn -y -f mp3 -copyts]
    }

    movie.transcode(@output_path, options)

    unless File.exist?(@output_path) && File.size?(@output_path)
      raise "Conversion failed: Output file was not created or is empty at #{@output_path}"
    end

    puts "Conversion successful: #{@output_path}"
    @output_path
  rescue => e
    puts "Error converting video to audio: #{e.message}"
    raise e
  end

  private

  def default_output_path
    dir = File.dirname(@input_path)
    base = File.basename(@input_path, ".*")
    File.join(dir, "#{base}_audio.mp3")
  end
end
