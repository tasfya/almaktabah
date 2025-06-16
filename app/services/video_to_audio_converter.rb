require "streamio-ffmpeg"
require "fileutils"

class VideoToAudioConverter
  def initialize(input_path, output_path = nil)
    @input_path = input_path.to_s
    @output_path = (output_path || default_output_path).to_s
  end

  def convert
    movie = FFMPEG::Movie.new(@input_path)
    puts "Converting video to optimized WAV: #{@input_path} -> #{@output_path}"

    options = {
      audio_bitrate: 128,
      audio_sample_rate: 44100,
      audio_channels: 2,
      custom: %w[
        -vn
        -y
        -fflags +fastseek+genpts
        -avoid_negative_ts make_zero
      ]
    }

    movie.transcode(@output_path, options)
    @output_path
  rescue => e
    puts "Error converting video to audio: #{e.message}"
    raise e
  end

  private

  def default_output_path
    dir = File.dirname(@input_path)
    base = File.basename(@input_path, ".*")
    File.join(dir, "#{base}_audio.wav")
  end
end
