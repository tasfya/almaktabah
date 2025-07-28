require "open3"
require "streamio-ffmpeg"
require "stringio"
require "securerandom"

class VideoToAudioConverter
  def initialize(input_io, bitrate: "128k")
    @input_io = ensure_io(input_io)
    @bitrate = bitrate
  end

  def convert
    output_io = StringIO.new

    # Validate bitrate to ensure it's in a safe format
    unless @bitrate =~ /\A\d+k\z/ # e.g., "128k", "256k"
      raise ArgumentError, "Invalid bitrate format. Must be like '128k'."
    end

    command = [
      "ffmpeg",
      "-loglevel", "error",
      "-i", "-",
      "-vn",
      "-f", "mp3",
      "-codec:a", "libmp3lame",
      "-b:a", @bitrate,
      "-ar", "44100",
      "-ac", "2",
      "-"
    ]

    Open3.popen2(*command) do |stdin, stdout, wait_thr|
      writer = Thread.new do
        IO.copy_stream(@input_io, stdin)
        stdin.close
      end

      IO.copy_stream(stdout, output_io)
      writer.join

      unless wait_thr.value.success?
        raise "ffmpeg conversion failed with status #{wait_thr.value.exitstatus}"
      end
    end

    output_io.rewind
    output_io
  rescue => e
    raise "Video to audio conversion failed: #{e.message}"
  end

  private

  def ensure_io(io)
    io.respond_to?(:read) ? io : StringIO.new(io)
  end
end
