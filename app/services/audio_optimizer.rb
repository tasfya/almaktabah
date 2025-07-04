require "streamio-ffmpeg"
require "fileutils"

class AudioOptimizer
  def initialize(input_path, output_path = nil, bitrate: "32k")
    @input_path = input_path.to_s
    @bitrate = bitrate
    @output_path = (output_path || default_output_path).to_s
  end

  def optimize
    movie = FFMPEG::Movie.new(@input_path)
    puts "Optimizing audio file: #{@input_path} to #{@output_path} as MP3 (speech-optimized)"

    options = {
      audio_codec: "libmp3lame",
      audio_bitrate: @bitrate,
      custom: %w[-y -fflags +fastseek+genpts -avoid_negative_ts make_zero]
    }

    movie.transcode(@output_path, options)
    @output_path
  rescue => e
    puts "Error optimizing audio: #{e.message}"
    FileUtils.cp(@input_path, @output_path)
    @output_path
  end

  private

  def default_output_path
    dir = File.dirname(@input_path)
    base = File.basename(@input_path, ".*")
    File.join(dir, "#{base}_optimized.mp3")
  end
end
