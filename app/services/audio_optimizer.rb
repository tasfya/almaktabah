# frozen_string_literal: true

require "open3"
require "stringio"

class AudioOptimizer
  DEFAULT_BITRATE = "64k"

  def initialize(input_io:, output_io: nil, bitrate: DEFAULT_BITRATE)
    @input_io  = ensure_io(input_io)
    @output_io = output_io || StringIO.new
    @bitrate   = bitrate
  end

  def optimize
    unless @bitrate =~ /\A\d+k\z/ # e.g., "64k", "128k", "256k"
      raise ArgumentError, "Invalid bitrate format. Bitrate must be in the format 'NNNk' (e.g., '128k')."
    end

    command = [
      "ffmpeg",
      "-loglevel", "error",
      "-i", "-",
      "-f", "mp3",
      "-codec:a", "libmp3lame",
      "-b:a", @bitrate, # Pass as a separate argument
      "-fflags", "+fastseek+genpts",
      "-avoid_negative_ts", "make_zero",
      "-"
    ]

    Open3.popen2(*command) do |stdin, stdout, wait_thr|
      writer = Thread.new { IO.copy_stream(@input_io, stdin); stdin.close }
      IO.copy_stream(stdout, @output_io)
      writer.join
      raise "ffmpeg failed (exit #{wait_thr.value.exitstatus})" unless wait_thr.value.success?
    end

    @output_io.rewind
    @output_io
  rescue => e
    raise "Audio optimization failed: #{e.message}"
  end

  private

  def ensure_io(io)
    io.respond_to?(:read) ? io : StringIO.new(io)
  end
end
