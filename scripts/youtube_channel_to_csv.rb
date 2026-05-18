#!/usr/bin/env ruby
# frozen_string_literal: true

# YouTube Channel to CSV Exporter
# Extracts playlists and videos from a YouTube channel and creates CSV files
# for importing into Almaktabah as lessons and lectures.
#
# Setup:
#   1. Install yt-dlp: brew install yt-dlp
#   2. Run: ruby youtube_channel_to_csv.rb <channel_url> [scholar_name]
#
# Examples:
#   ruby youtube_channel_to_csv.rb "https://www.youtube.com/@channel_name"
#   ruby youtube_channel_to_csv.rb "https://www.youtube.com/@channel_name" "الشيخ فلان"
#
# Output:
#   Creates a folder with:
#   - all_lessons.csv: All playlist videos with series column
#   - lectures.csv: Standalone videos not in any playlist
#   - SUMMARY.txt: Summary of extracted content

require "json"
require "csv"
require "fileutils"
require "logger"
require "open3"

class YoutubeChannelToCsv
  OUTPUT_DIR = ENV.fetch("OUTPUT_DIR", File.expand_path("~/youtube_channel_exports"))
  DEFAULT_LECTURE_KIND = ENV.fetch("DEFAULT_LECTURE_KIND", "conference")

  def initialize(channel_url, scholar_name = nil)
    @channel_url = channel_url
    @scholar_name = scholar_name
    @logger = Logger.new($stdout)
    @logger.formatter = proc { |severity, datetime, _, msg| "[#{datetime.strftime('%H:%M:%S')}] #{severity}: #{msg}\n" }

    @channel_id = extract_channel_id(channel_url)
    @output_path = File.join(OUTPUT_DIR, @channel_id || "channel_#{Time.now.to_i}")
    FileUtils.mkdir_p(@output_path)
  end

  def run
    @logger.info "YouTube Channel to CSV Exporter"
    @logger.info "Channel URL: #{@channel_url}"
    @logger.info "Output directory: #{@output_path}"
    @logger.info ""

    # Step 1: Extract playlists
    @logger.info "=== Extracting Playlists ==="
    playlists = extract_playlists
    @logger.info "Found #{playlists.size} playlists"

    # Step 2: Extract videos from each playlist
    @logger.info ""
    @logger.info "=== Extracting Playlist Videos ==="
    playlist_videos = {}
    all_playlist_video_ids = []

    playlists.each_with_index do |playlist, idx|
      @logger.info "[#{idx + 1}/#{playlists.size}] #{playlist[:title]}"
      videos = extract_playlist_videos(playlist[:id])
      playlist_videos[playlist[:title]] = videos
      all_playlist_video_ids.concat(videos.map { |v| v[:id] })
      @logger.info "  -> #{videos.size} videos"
    end

    # Step 3: Extract all channel videos
    @logger.info ""
    @logger.info "=== Extracting All Channel Videos ==="
    all_videos = extract_channel_videos
    @logger.info "Found #{all_videos.size} total videos"

    # Step 4: Find standalone videos (not in any playlist)
    standalone_videos = all_videos.reject { |v| all_playlist_video_ids.include?(v[:id]) }
    @logger.info "Found #{standalone_videos.size} standalone videos (lectures)"

    # Step 5: Generate CSV files
    @logger.info ""
    @logger.info "=== Generating CSV Files ==="

    lessons_count = generate_lessons_csv(playlist_videos)
    lectures_count = generate_lectures_csv(standalone_videos)
    generate_summary(playlists, playlist_videos, standalone_videos)

    @logger.info ""
    @logger.info "=== Complete ==="
    @logger.info "Output directory: #{@output_path}"
    @logger.info "Files created:"
    @logger.info "  - all_lessons.csv (#{lessons_count} lessons from #{playlists.size} series)"
    @logger.info "  - lectures.csv (#{lectures_count} lectures)"
    @logger.info "  - SUMMARY.txt"
  end

  private

  def extract_channel_id(url)
    # Extract channel handle or ID from URL
    if url =~ /@([^\/\?]+)/
      $1
    elsif url =~ /channel\/([^\/\?]+)/
      $1
    else
      nil
    end
  end

  def extract_playlists
    @logger.info "Fetching playlists..."
    json = run_ytdlp("#{@channel_url}/playlists")
    return [] unless json

    entries = json["entries"] || []
    entries.map do |entry|
      {
        id: entry["id"],
        title: entry["title"],
        url: entry["url"]
      }
    end
  end

  def extract_playlist_videos(playlist_id)
    json = run_ytdlp("https://www.youtube.com/playlist?list=#{playlist_id}")
    return [] unless json

    entries = json["entries"] || []
    entries.map.with_index do |entry, idx|
      {
        id: entry["id"],
        title: clean_title(entry["title"]),
        position: idx + 1,
        youtube_url: "https://www.youtube.com/watch?v=#{entry['id']}"
      }
    end
  end

  def extract_channel_videos
    @logger.info "Fetching all channel videos..."
    json = run_ytdlp("#{@channel_url}/videos")
    return [] unless json

    entries = json["entries"] || []
    entries.map do |entry|
      {
        id: entry["id"],
        title: clean_title(entry["title"]),
        youtube_url: "https://www.youtube.com/watch?v=#{entry['id']}"
      }
    end
  end

  def run_ytdlp(url)
    cmd = [ "yt-dlp", "--flat-playlist", "-J", url ]
    stdout, stderr, status = Open3.capture3(*cmd)

    unless status.success?
      @logger.error "yt-dlp failed: #{stderr}"
      return nil
    end

    JSON.parse(stdout)
  rescue JSON::ParserError => e
    @logger.error "Failed to parse yt-dlp output: #{e.message}"
    nil
  end

  def clean_title(title)
    return "" if title.nil?

    cleaned = title.dup

    # Remove scholar name and variations
    if @scholar_name
      # Exact match
      cleaned.gsub!(/#{Regexp.escape(@scholar_name)}/, "")

      # Build variations: with/without dots, with/without titles
      name_parts = @scholar_name.gsub(/[.ذد]\s*/, "").strip
      variations = [
        @scholar_name,
        name_parts,
        "د. #{name_parts}",
        "د #{name_parts}",
        "ذ. #{name_parts}",
        "ذ #{name_parts}",
        "الشيخ #{name_parts}",
        "الدكتور #{name_parts}",
        name_parts.gsub(/\s+/, "_"),
        "##{name_parts.gsub(/\s+/, '_')}",
        "#الدكتور_#{name_parts.gsub(/\s+/, '_')}"
      ]

      variations.each do |variant|
        cleaned.gsub!(/#{Regexp.escape(variant)}/i, "")
      end
    end

    # Clean up whitespace and punctuation
    cleaned.gsub!(/\s+/, " ")
    cleaned.strip!
    cleaned.gsub!(/^\.\s*/, "")
    cleaned.gsub!(/\s*\.$/, "")
    cleaned.gsub!(/^\s*-\s*/, "")
    cleaned.gsub!(/\s*-\s*$/, "")
    cleaned.gsub!(/#\s*$/, "")
    cleaned.strip!

    cleaned
  end

  def generate_lessons_csv(playlist_videos)
    csv_path = File.join(@output_path, "all_lessons.csv")
    count = 0

    CSV.open(csv_path, "w") do |csv|
      csv << [ "series", "title", "position", "youtube_url" ]

      playlist_videos.each do |series_title, videos|
        videos.each do |video|
          csv << [ series_title, video[:title], video[:position], video[:youtube_url] ]
          count += 1
        end
      end
    end

    @logger.info "Created: all_lessons.csv (#{count} rows)"
    count
  end

  def generate_lectures_csv(videos)
    csv_path = File.join(@output_path, "lectures.csv")

    CSV.open(csv_path, "w") do |csv|
      csv << [ "title", "kind", "youtube_url" ]

      videos.each do |video|
        # Determine kind based on title
        kind = video[:title].include?("خطبة") ? "sermon" : DEFAULT_LECTURE_KIND
        csv << [ video[:title], kind, video[:youtube_url] ]
      end
    end

    @logger.info "Created: lectures.csv (#{videos.size} rows)"
    videos.size
  end

  def generate_summary(playlists, playlist_videos, standalone_videos)
    summary_path = File.join(@output_path, "SUMMARY.txt")

    File.open(summary_path, "w") do |f|
      f.puts "=== YouTube Channel Export Summary ==="
      f.puts "Channel URL: #{@channel_url}"
      f.puts "Scholar name: #{@scholar_name || '(not specified)'}"
      f.puts "Export date: #{Time.now}"
      f.puts ""
      f.puts "=== LESSONS (from playlists) ==="
      f.puts "#{playlists.size} playlists"
      f.puts ""

      playlist_videos.each do |series_title, videos|
        f.puts "  - #{series_title}: #{videos.size} lessons"
      end

      total_lessons = playlist_videos.values.sum(&:size)
      f.puts ""
      f.puts "Total lessons: #{total_lessons}"
      f.puts ""
      f.puts "=== LECTURES (standalone videos) ==="
      f.puts "#{standalone_videos.size} lectures"
      f.puts ""
      f.puts "=== FILES ==="
      f.puts "  - all_lessons.csv: Import via Scholar > Import Lessons from CSV"
      f.puts "  - lectures.csv: Import via Scholar > Import Lectures from CSV"
    end

    @logger.info "Created: SUMMARY.txt"
  end
end

# Run if executed directly
if __FILE__ == $PROGRAM_NAME
  if ARGV.size < 2
    puts "Usage: ruby youtube_channel_to_csv.rb <channel_url> <scholar_name>"
    puts ""
    puts "Arguments:"
    puts "  channel_url  - YouTube channel URL"
    puts "  scholar_name - Scholar name to remove from video titles"
    puts ""
    puts "Examples:"
    puts "  ruby youtube_channel_to_csv.rb 'https://www.youtube.com/@channel' 'د. يوسف العلمي المروني'"
    puts "  ruby youtube_channel_to_csv.rb 'https://www.youtube.com/@channel' 'الشيخ محمد'"
    puts ""
    puts "Environment variables:"
    puts "  OUTPUT_DIR: Output directory (default: ~/youtube_channel_exports)"
    puts "  DEFAULT_LECTURE_KIND: Default kind for lectures (default: conference)"
    exit 1
  end

  channel_url = ARGV[0]
  scholar_name = ARGV[1]

  YoutubeChannelToCsv.new(channel_url, scholar_name).run
end
