require "streamio-ffmpeg"
require "fileutils"

class AudioOptimizer
  # format: :opus, :aac, or :mp3 (default :opus)
  def initialize(input_path, output_path = nil, format: :opus, bitrate: nil)
    @input_path = input_path.to_s
    @format = format.to_sym
    @bitrate = bitrate || default_bitrate
    @output_path = (output_path || default_output_path).to_s
  end

  def optimize
    movie = FFMPEG::Movie.new(@input_path)
    puts "Optimizing audio file: #{@input_path} to #{@output_path} as #{@format.upcase}"

    options = ffmpeg_options_for(@format)

    movie.transcode(@output_path, options)
    @output_path
  rescue => e
    puts "Error optimizing audio: #{e.message}"
    FileUtils.cp(@input_path, @output_path)
    @output_path
  end

  private

  def default_bitrate
    case @format
    when :opus then "32k"
    when :aac then "48k"
    when :mp3 then "64k"
    else "32k"
    end
  end

  def ffmpeg_options_for(format)
    case format
    when :opus
      {
        audio_codec: "libopus",
        audio_bitrate: @bitrate,
        custom: %w[-y -fflags +fastseek+genpts -avoid_negative_ts make_zero]
      }
    when :aac
      {
        audio_codec: "aac",
        audio_bitrate: @bitrate,
        custom: %w[-y -fflags +fastseek+genpts -avoid_negative_ts make_zero]
      }
    when :mp3
      {
        audio_codec: "libmp3lame",
        audio_bitrate: @bitrate,
        custom: %w[-y -fflags +fastseek+genpts -avoid_negative_ts make_zero]
      }
    else
      raise "Unsupported format: #{format}"
    end
  end

  def default_output_path
    dir = File.dirname(@input_path)
    base = File.basename(@input_path, ".*")
    ext = case @format
    when :opus then "opus"
    when :aac then "m4a"
    when :mp3 then "mp3"
    else "audio"
    end
    File.join(dir, "#{base}_optimized.#{ext}")
  end
end
