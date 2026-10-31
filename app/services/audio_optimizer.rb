require "streamio-ffmpeg"
require "fileutils"

class AudioOptimizer
  def initialize(input_path, output_path = nil, bitrate: "32k")
    @input_path = input_path.to_s
    @bitrate = bitrate
    @output_path = (output_path || default_output_path).to_s
  end

  def optimize
    single_copy = single_copy_of_doubled_input
    movie = FFMPEG::Movie.new(single_copy&.path || @input_path)
    input_duration = movie.duration
    puts "Optimizing audio file: #{@input_path} to #{@output_path} as MP3 (speech-optimized)"
    puts "Input audio duration: #{input_duration.round(2)}s"

    options = {
      audio_codec: "libmp3lame",
      audio_bitrate: @bitrate,
      custom: %w[-y]
    }

    movie.transcode(@output_path, options)

    # Validate output duration matches input
    output_movie = FFMPEG::Movie.new(@output_path)
    output_duration = output_movie.duration
    duration_diff = (input_duration - output_duration).abs

    puts "Output audio duration: #{output_duration.round(2)}s (diff: #{duration_diff.round(2)}s)"

    if duration_diff > 2.0
      raise "Duration mismatch during optimization! Input: #{input_duration.round(2)}s, Output: #{output_duration.round(2)}s"
    end

    @output_path
  rescue => e
    puts "Error optimizing audio: #{e.message}"
    raise e
  ensure
    single_copy&.close!
  end

  private

  # Some imported files are the same MP3 written twice back to back. The header
  # describes one copy, but decoding plays both, so transcode one copy only.
  def single_copy_of_doubled_input
    size = File.size(@input_path)
    return if size.zero? || size.odd?

    half = size / 2
    first = File.binread(@input_path, half, 0)
    return unless first == File.binread(@input_path, half, half)

    puts "Input is two identical copies of one file, optimizing a single copy"
    tempfile = Tempfile.new([ "single_copy", File.extname(@input_path) ], binmode: true)
    tempfile.write(first)
    tempfile.flush
    tempfile
  end

  def default_output_path
    dir = File.dirname(@input_path)
    base = File.basename(@input_path, ".*")
    File.join(dir, "#{base}_optimized.mp3")
  end
end
