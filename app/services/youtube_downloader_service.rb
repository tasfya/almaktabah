require "open3"
require "fileutils"
require "json"

class YoutubeDownloaderService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :url, :download_path, :format, :quality, :verbose
  attr_reader :progress, :download_info, :errors

  def initialize(url:, download_path: nil, format: "mp4", quality: "best", verbose: true)
    @url = url.to_s.strip
    @download_path = download_path || default_download_path
    @format = format
    @quality = quality
    @verbose = verbose
    @progress = {}
    @download_info = {}
    @errors = []

    ensure_directory_exists
  end

  def download
    print_header

    return get_video_info unless can_download?

    print_info("Starting download process...")

    info = get_video_info
    return false unless info

    @download_info = info
    print_video_details(info)

    download_with_external_tool
  end

  def get_video_info
    print_info("Fetching video information...")

    return nil unless valid_youtube_url?

    begin
      youtube_info = YoutubeInfoService.new(url: @url) if defined?(YoutubeInfoService)

      if youtube_info
        info = youtube_info.get_video_info

        if info
          info["video_id"] = youtube_info.extract_video_id
          info["thumbnail_url"] = youtube_info.get_thumbnail_url
          info["embed_url"] = youtube_info.get_embed_url
          print_success("Successfully extracted video information")
          Rails.logger.info "Extracted YouTube info for: #{@url}"
        else
          print_error("Failed to extract YouTube info using YoutubeInfoService")
          Rails.logger.error "Failed to extract YouTube info for: #{@url}"
        end
      else
        info = get_info_with_ytdlp
      end

      info
    rescue => e
      print_error("Error getting video info: #{e.message}")
      @errors << e.message
      nil
    end
  end

  def extract_video_id
    return nil unless valid_youtube_url?
    video_id = @url[/(?:youtube\.com\/watch\?v=|youtu\.be\/|embed\/|v\/|shorts\/)([\w\-]{11})/, 1]
    print_info("Extracted video ID: #{video_id}") if video_id && @verbose
    video_id
  end

  def can_download?
    available = !!get_available_tool
    if available
      print_success("Found download tool: #{get_available_tool}")
    else
      print_error("No download tool found!")
      print_info("Installation suggestion: #{installation_suggestion}")
    end
    available
  end

  def installation_suggestion
    if system("which pacman > /dev/null 2>&1")
      "sudo pacman -S yt-dlp ffmpeg"
    elsif system("which apt > /dev/null 2>&1")
      "sudo apt install yt-dlp ffmpeg"
    elsif system("which dnf > /dev/null 2>&1")
      "sudo dnf install yt-dlp ffmpeg"
    elsif system("which yum > /dev/null 2>&1")
      "sudo yum install yt-dlp ffmpeg"
    elsif system("which brew > /dev/null 2>&1")
      "brew install yt-dlp ffmpeg"
    else
      "Install yt-dlp and ffmpeg using your system's package manager"
    end
  end

  def get_available_formats
    print_info("Fetching available formats...")

    return [] unless valid_youtube_url? && can_download?

    tool = get_available_tool
    command = [ tool, "--list-formats", @url ]

    begin
      stdout, stderr, status = Open3.capture3(*command)

      if status.success?
        print_success("Successfully retrieved format list")
        parse_format_list(stdout)
      else
        print_error("Failed to get format list: #{stderr}")
        []
      end
    rescue => e
      print_error("Error getting formats: #{e.message}")
      []
    end
  end

  private

  def print_header
    return unless @verbose
    puts "\n" + "="*60
    puts "YouTube Downloader Service"
    puts "="*60
    puts "URL: #{@url}"
    puts "Download Path: #{@download_path}"
    puts "Format: #{@format}"
    puts "Quality: #{@quality}"
    puts "="*60 + "\n"
  end

  def print_info(message)
    return unless @verbose
    puts "[INFO] #{message}"
  end

  def print_success(message)
    return unless @verbose
    puts "[SUCCESS] #{message}"
  end

  def print_error(message)
    return unless @verbose
    puts "[ERROR] #{message}"
  end

  def print_progress(message)
    return unless @verbose
    puts "[PROGRESS] #{message}"
  end

  def print_video_details(info)
    return unless @verbose && info

    puts "\n" + "-"*40
    puts "Video Details:"
    puts "-"*40
    puts "Title: #{info['title'] || 'N/A'}"
    puts "Duration: #{info['duration'] || 'N/A'}"
    puts "View Count: #{info['view_count'] || 'N/A'}"
    puts "Upload Date: #{info['upload_date'] || 'N/A'}"
    puts "Uploader: #{info['uploader'] || 'N/A'}"
    puts "Video ID: #{info['video_id'] || extract_video_id}"
    puts "-"*40 + "\n"
  end

  def valid_youtube_url?
    valid = @url.present? && @url.match?(/\Ahttps?:\/\/(www\.)?(youtube\.com|youtu\.be)\//)
    print_error("Invalid YouTube URL: #{@url}") unless valid
    valid
  end

  def ensure_directory_exists
    unless Dir.exist?(@download_path)
      print_info("Creating download directory: #{@download_path}")
      FileUtils.mkdir_p(@download_path)
    end
  end

  def default_download_path
    Rails.root.join("storage", "youtube_downloads")
  end

  def get_available_tool
    @available_tool ||= %w[yt-dlp youtube-dl].find do |tool|
      system("which #{tool} > /dev/null 2>&1")
    end
  end

  def get_info_with_ytdlp
    print_info("Using yt-dlp to fetch video information...")

    tool = get_available_tool
    return nil unless tool

    command = [ tool, "--dump-json", "--no-playlist", @url ]

    begin
      stdout, stderr, status = Open3.capture3(*command)

      if status.success?
        info = JSON.parse(stdout)
        print_success("Successfully retrieved video info via yt-dlp")
        info
      else
        print_error("Failed to get video info: #{stderr}")
        nil
      end
    rescue JSON::ParserError => e
      print_error("Failed to parse video info JSON: #{e.message}")
      nil
    rescue => e
      print_error("Error getting video info: #{e.message}")
      nil
    end
  end

  def build_download_command
    tool = get_available_tool
    raise "No supported tool found" unless tool
    raise "Invalid YouTube URL" unless valid_youtube_url?

    video_id = extract_video_id
    output_template = File.join(@download_path, "%(title)s_%(id)s.%(ext)s")
    raise "Invalid output path" unless valid_output_path?(output_template)

    cmd = [ tool ]

    # Format selection
    if @quality == "best"
      cmd += [ "--format", "best[ext=#{@format}]/best" ]
    elsif @quality == "worst"
      cmd += [ "--format", "worst[ext=#{@format}]/worst" ]
    else
      cmd += [ "--format", "#{@quality}[ext=#{@format}]/#{@quality}" ]
    end

    # Output options
    cmd += [ "--merge-output-format", @format ] if @format
    cmd += [ "--output", output_template ]
    cmd += [ "--no-playlist" ]

    # Progress and verbose options
    cmd += [ "--progress", "--verbose" ] if @verbose

    # Add URL
    cmd += [ @url ]

    print_info("Download command: #{cmd.join(' ')}")
    cmd
  end

  def download_with_external_tool
    video_id = extract_video_id
    return false unless video_id

    begin
      command = build_download_command
      print_info("Executing download command...")

      start_time = Time.now

      Open3.popen3(*command) do |stdin, stdout, stderr, wait_thr|
        # Handle stdout in a separate thread
        stdout_thread = Thread.new do
          stdout.each_line do |line|
            line = line.strip
            next if line.empty?

            print_progress(line)
            Rails.logger.info "[yt-dlp STDOUT] #{line}"

            # Parse progress information
            parse_progress_line(line)
          end
        end

        # Handle stderr in a separate thread
        stderr_thread = Thread.new do
          stderr.each_line do |line|
            line = line.strip
            next if line.empty?

            # yt-dlp often prints progress and info to stderr
            if line.include?("[download]") || line.include?("%")
              print_progress(line)
            else
              print_info(line)
            end

            Rails.logger.info "[yt-dlp STDERR] #{line}"
            parse_progress_line(line)
          end
        end

        # Wait for both threads to complete
        stdout_thread.join
        stderr_thread.join

        exit_status = wait_thr.value
        end_time = Time.now
        duration = end_time - start_time

        if exit_status.success?
          print_success("Download completed successfully in #{duration.round(2)} seconds!")
          Rails.logger.info "Download succeeded in #{duration.round(2)} seconds"

          downloaded_file = find_downloaded_file(video_id)
          if downloaded_file
            print_success("File saved to: #{downloaded_file}")
            print_file_info(downloaded_file)
          end

          return downloaded_file
        else
          print_error("Download failed with exit code #{exit_status.exitstatus}")
          Rails.logger.error "Download failed with exit code #{exit_status.exitstatus}"
          return false
        end
      end

    rescue => e
      print_error("Download error: #{e.message}")
      Rails.logger.error "Download error: #{e.message}"
      @errors << e.message
      false
    end
  end

  def parse_progress_line(line)
    # Parse download progress from yt-dlp output
    if line.match(/\[download\]\s+(\d+\.?\d*)%/)
      @progress[:percentage] = $1.to_f
    end

    if line.match(/(\d+\.?\d*\w+\/s)/)
      @progress[:speed] = $1
    end

    if line.match(/ETA\s+(\d+:\d+)/)
      @progress[:eta] = $1
    end
  end

  def parse_format_list(output)
    formats = []
    output.split("\n").each do |line|
      if line.match(/^(\w+)\s+(\w+)\s+(\d+x\d+|\w+)\s+/)
        formats << {
          format_id: $1,
          extension: $2,
          resolution: $3
        }
      end
    end
    formats
  end

  def valid_output_path?(path)
    # Allow absolute paths and basic safe characters, including template variables
    path.to_s.match?(/\A[\/\w\-().%\s]+\.%\(ext\)s\z/)
  end

  def find_downloaded_file(video_id)
    print_info("Searching for downloaded file...")

    extensions = %w[mp4 webm mkv m4v avi flv]

    # Search for files with video_id in the filename
    Dir.glob(File.join(@download_path, "*#{video_id}*")).each do |file|
      if File.file?(file) && extensions.any? { |ext| file.end_with?(ext) }
        print_success("Found downloaded file: #{file}")
        return file
      end
    end

    # Fallback: search for recently created files
    recent_files = Dir.glob(File.join(@download_path, "*"))
                     .select { |f| File.file?(f) }
                     .select { |f| extensions.any? { |ext| f.end_with?(ext) } }
                     .sort_by { |f| File.mtime(f) }
                     .reverse

    if recent_files.any?
      print_info("Found recent file (assuming it's the download): #{recent_files.first}")
      return recent_files.first
    end

    print_error("Could not find downloaded file")
    false
  end

  def print_file_info(file_path)
    return unless @verbose && File.exist?(file_path)

    file_size = File.size(file_path)
    file_size_mb = (file_size / 1024.0 / 1024.0).round(2)

    puts "\n" + "-"*40
    puts "Downloaded File Information:"
    puts "-"*40
    puts "Path: #{file_path}"
    puts "Size: #{file_size_mb} MB (#{file_size} bytes)"
    puts "Created: #{File.ctime(file_path)}"
    puts "Modified: #{File.mtime(file_path)}"
    puts "-"*40 + "\n"
  end
end
