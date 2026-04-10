# frozen_string_literal: true

require "streamio-ffmpeg"
require "fileutils"
require "tempfile"

class AudioDeduplicationService
  class ProcessingError < StandardError; end

  # Similarity threshold for considering segments as duplicates (0.0 - 1.0)
  DEFAULT_THRESHOLD = 0.85
  # Minimum file duration in seconds to process
  DEFAULT_MIN_DURATION = 60
  # Sample duration in seconds for comparison
  SAMPLE_DURATION = 30
  # Number of comparison points within each segment
  COMPARISON_POINTS = 5

  attr_reader :threshold, :min_duration

  def initialize(threshold: DEFAULT_THRESHOLD, min_duration: DEFAULT_MIN_DURATION)
    @threshold = threshold
    @min_duration = min_duration
  end

  # Analyze a folder of MP3 files for duplicates (dry run)
  def analyze_folder(input_folder)
    validate_folder!(input_folder)

    files = Dir.glob(File.join(input_folder, "**", "*.mp3"))
    result = {
      total_files: files.count,
      analyzed: 0,
      duplicates_found: 0,
      duplicate_files: [],
      errors: []
    }

    files.each do |file_path|
      begin
        analysis = analyze_file(file_path)
        result[:analyzed] += 1

        if analysis[:is_duplicate]
          result[:duplicates_found] += 1
          result[:duplicate_files] << {
            path: file_path,
            original_duration: analysis[:duration],
            estimated_clean_duration: analysis[:clean_duration],
            repeat_factor: analysis[:repeat_factor]
          }
          puts "  [DUPLICATE] #{File.basename(file_path)}: #{format_duration(analysis[:duration])} -> #{format_duration(analysis[:clean_duration])} (#{analysis[:repeat_factor]}x repeat)"
        else
          puts "  [OK] #{File.basename(file_path)}: #{format_duration(analysis[:duration])}"
        end
      rescue StandardError => e
        result[:errors] << { path: file_path, error: e.message }
        puts "  [ERROR] #{File.basename(file_path)}: #{e.message}"
      end
    end

    result
  end

  # Process a folder, removing duplicates and saving to output folder
  def process_folder(input_folder, output_folder)
    validate_folder!(input_folder)
    FileUtils.mkdir_p(output_folder)

    files = Dir.glob(File.join(input_folder, "**", "*.mp3"))
    result = {
      total_files: files.count,
      processed: 0,
      duplicates_found: 0,
      errors: []
    }

    files.each do |file_path|
      begin
        # Preserve relative path structure
        relative_path = file_path.sub(input_folder, "").sub(%r{^/}, "")
        output_path = File.join(output_folder, relative_path)
        FileUtils.mkdir_p(File.dirname(output_path))

        analysis = analyze_file(file_path)

        if analysis[:is_duplicate]
          result[:duplicates_found] += 1
          puts "  [FIXING] #{File.basename(file_path)}: trimming from #{format_duration(analysis[:duration])} to #{format_duration(analysis[:clean_duration])}"
          trim_audio(file_path, output_path, analysis[:clean_duration])
        else
          puts "  [COPYING] #{File.basename(file_path)}: no duplication detected"
          FileUtils.cp(file_path, output_path)
        end

        result[:processed] += 1
      rescue StandardError => e
        result[:errors] << { path: file_path, error: e.message }
        puts "  [ERROR] #{File.basename(file_path)}: #{e.message}"
      end
    end

    result
  end

  # Analyze a single audio file for internal duplication
  def analyze_file(file_path)
    movie = FFMPEG::Movie.new(file_path)
    duration = movie.duration

    return { is_duplicate: false, duration: duration, reason: "too_short" } if duration < min_duration

    # Check for 2x duplication (most common case)
    if duration_suggests_duplication?(duration, 2)
      half_duration = duration / 2.0
      if segments_match?(file_path, 0, half_duration, duration)
        return {
          is_duplicate: true,
          duration: duration,
          clean_duration: half_duration,
          repeat_factor: 2
        }
      end
    end

    # Check for 3x duplication
    if duration_suggests_duplication?(duration, 3)
      third_duration = duration / 3.0
      if segments_match?(file_path, 0, third_duration, duration) &&
         segments_match?(file_path, 0, third_duration * 2, duration)
        return {
          is_duplicate: true,
          duration: duration,
          clean_duration: third_duration,
          repeat_factor: 3
        }
      end
    end

    { is_duplicate: false, duration: duration }
  end

  # Analyze and fix a single file in place (with backup)
  def fix_file!(file_path, backup: true)
    analysis = analyze_file(file_path)

    return { fixed: false, reason: "not_duplicate" } unless analysis[:is_duplicate]

    if backup
      backup_path = "#{file_path}.backup"
      FileUtils.cp(file_path, backup_path)
    end

    temp_output = Tempfile.new([ "dedup", ".mp3" ])
    begin
      trim_audio(file_path, temp_output.path, analysis[:clean_duration])
      FileUtils.mv(temp_output.path, file_path)

      {
        fixed: true,
        original_duration: analysis[:duration],
        new_duration: analysis[:clean_duration],
        repeat_factor: analysis[:repeat_factor],
        backup_path: backup ? backup_path : nil
      }
    ensure
      temp_output.close
      temp_output.unlink if File.exist?(temp_output.path)
    end
  end

  private

  def validate_folder!(folder)
    raise ProcessingError, "Folder does not exist: #{folder}" unless File.directory?(folder)
  end

  # Check if duration is close to a multiple of a base duration
  def duration_suggests_duplication?(duration, factor)
    # The file should be divisible by the factor with minimal remainder
    # Allow 5% tolerance for slight variations
    segment_duration = duration / factor.to_f
    segment_duration >= min_duration
  end

  # Compare two segments of audio to see if they match
  def segments_match?(file_path, start1, start2, total_duration)
    # Ensure we don't read past the end
    segment_length = [ SAMPLE_DURATION, total_duration - start2 ].min
    return false if segment_length < 10

    # Get audio statistics at multiple points and compare
    stats1 = extract_audio_stats(file_path, start1, segment_length)
    stats2 = extract_audio_stats(file_path, start2, segment_length)

    return false if stats1.nil? || stats2.nil?

    calculate_similarity(stats1, stats2) >= threshold
  end

  # Extract audio statistics (mean volume, RMS) for a segment
  def extract_audio_stats(file_path, start_time, duration)
    # Use FFmpeg to extract audio statistics
    cmd = [
      "ffmpeg", "-y",
      "-ss", start_time.to_s,
      "-t", duration.to_s,
      "-i", file_path,
      "-af", "astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-",
      "-f", "null", "-"
    ]

    output = `#{cmd.shelljoin} 2>&1`

    # Extract RMS levels from output
    rms_values = output.scan(/lavfi\.astats\.Overall\.RMS_level=(-?\d+\.?\d*)/).flatten.map(&:to_f)

    return nil if rms_values.empty?

    {
      mean_rms: rms_values.sum / rms_values.size,
      rms_values: rms_values,
      count: rms_values.size
    }
  rescue StandardError => e
    Rails.logger.warn("Failed to extract audio stats: #{e.message}")
    nil
  end

  # Calculate similarity between two audio stat profiles
  def calculate_similarity(stats1, stats2)
    return 0.0 if stats1[:count].zero? || stats2[:count].zero?

    # Compare mean RMS levels
    rms_diff = (stats1[:mean_rms] - stats2[:mean_rms]).abs

    # RMS is in dB, typical range is -60 to 0
    # Difference of 3dB is noticeable, 1dB is barely perceptible
    # Map to similarity score where smaller diff = higher similarity
    max_acceptable_diff = 6.0 # dB
    rms_similarity = [ 1.0 - (rms_diff / max_acceptable_diff), 0.0 ].max

    # Also compare distribution of values if we have multiple samples
    distribution_similarity = 1.0
    if stats1[:rms_values].size >= 3 && stats2[:rms_values].size >= 3
      # Compare variance/spread of values
      var1 = variance(stats1[:rms_values])
      var2 = variance(stats2[:rms_values])
      var_diff = (var1 - var2).abs
      max_var_diff = 20.0
      distribution_similarity = [ 1.0 - (var_diff / max_var_diff), 0.0 ].max
    end

    # Weight RMS more heavily than distribution
    (rms_similarity * 0.7) + (distribution_similarity * 0.3)
  end

  def variance(values)
    return 0.0 if values.empty?

    mean = values.sum / values.size.to_f
    squared_diffs = values.map { |v| (v - mean) ** 2 }
    squared_diffs.sum / values.size.to_f
  end

  # Trim audio file to specified duration
  def trim_audio(input_path, output_path, duration)
    cmd = [
      "ffmpeg", "-y",
      "-i", input_path,
      "-t", duration.to_s,
      "-c", "copy", # Fast copy without re-encoding
      output_path
    ]

    success = system(*cmd, out: File::NULL, err: File::NULL)
    raise ProcessingError, "Failed to trim audio file: #{input_path}" unless success

    output_path
  end

  def format_duration(seconds)
    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i
    secs = (seconds % 60).to_i

    if hours > 0
      format("%d:%02d:%02d", hours, minutes, secs)
    else
      format("%d:%02d", minutes, secs)
    end
  end
end
