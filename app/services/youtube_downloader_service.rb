class YoutubeDownloaderService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :url, :download_path, :format

  def initialize(url:, download_path: nil, format: "info")
    @url = url
    @download_path = download_path || default_download_path
    @format = format
  end

  def download
    if can_download?
      download_with_external_tool
    else
      Rails.logger.warn "External tools not available. Only extracting video info."
      get_video_info
    end
  end

  def download_audio_only
    if can_download?
      @format = "mp3"
      download_with_external_tool
    else
      Rails.logger.warn "External tools not available for audio download."
      false
    end
  end

  def get_video_info
    return nil unless valid_youtube_url?

    youtube_info = YoutubeInfoService.new(url: @url)
    info = youtube_info.get_video_info

    if info
      # Enhance with additional extracted info
      info["video_id"] = youtube_info.extract_video_id
      info["thumbnail_url"] = youtube_info.get_thumbnail_url
      info["embed_url"] = youtube_info.get_embed_url

      Rails.logger.info "Successfully extracted YouTube info for: #{@url}"
      info
    else
      Rails.logger.error "Failed to get YouTube info for: #{@url}"
      nil
    end
  end

  def extract_video_id
    return nil unless valid_youtube_url?

    # Extract video ID from various YouTube URL formats
    if @url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/v\/|youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})/)
      $1
    else
      nil
    end
  end

  # Method to check if we can download (requires external tools)
  def can_download?
    system("which yt-dlp > /dev/null 2>&1") ||
    system("which youtube-dl > /dev/null 2>&1")
  end

  # Method to suggest installation of required tools
  def installation_suggestion
    if system("which pacman > /dev/null 2>&1")
      "Install required tools with: sudo pacman -S yt-dlp ffmpeg"
    elsif system("which apt > /dev/null 2>&1")
      "Install required tools with: sudo apt install yt-dlp ffmpeg"
    elsif system("which dnf > /dev/null 2>&1")
      "Install required tools with: sudo dnf install yt-dlp ffmpeg"
    elsif system("which yum > /dev/null 2>&1")
      "Install required tools with: sudo yum install yt-dlp ffmpeg"
    else
      "Install yt-dlp and ffmpeg using your system's package manager"
    end
  end

  private

  def valid_youtube_url?
    return false unless @url.present?
    @url.include?("youtube.com") || @url.include?("youtu.be")
  end

  def default_download_path
    Rails.root.join("storage", "youtube_downloads")
  end

  def download_with_external_tool
    ensure_directory_exists

    video_id = extract_video_id
    return false unless video_id

    output_path = File.join(@download_path, "#{video_id}.%(ext)s")
    command = build_download_command(output_path)

    Rails.logger.info "Executing: #{command}"
    result = system(command)

    if result
      find_downloaded_file(video_id)
    else
      Rails.logger.error "Download command failed"
      false
    end
  end

  def build_download_command(output_path)
    tool = get_available_tool
    return nil unless tool

    cmd = [ tool ]

    case @format
    when "mp3"
      cmd += [ "--extract-audio", "--audio-format", "mp3", "--audio-quality", "192K" ]
    when "mp4"
      cmd += [ "--format", "best[ext=mp4]/best", "--merge-output-format", "mp4" ]
    end

    cmd += [ "--output", "'#{output_path}'", "--no-playlist", "'#{@url}'" ]
    cmd.join(" ")
  end

  def get_available_tool
    return "yt-dlp" if system("which yt-dlp > /dev/null 2>&1")
    return "youtube-dl" if system("which youtube-dl > /dev/null 2>&1")
    nil
  end

  def ensure_directory_exists
    FileUtils.mkdir_p(@download_path) unless Dir.exist?(@download_path)
  end

  def find_downloaded_file(video_id)
    extensions = @format == "mp3" ? [ "mp3" ] : [ "mp4", "webm", "mkv" ]

    extensions.each do |ext|
      file_path = File.join(@download_path, "#{video_id}.#{ext}")
      return file_path if File.exist?(file_path)
    end

    false
  end
end
