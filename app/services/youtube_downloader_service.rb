require "open3"
require "fileutils"

class YoutubeDownloaderService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :url, :download_path, :format

  def initialize(url:, download_path: nil, format: "info")
    @url = url.to_s.strip
    @download_path = download_path || default_download_path
    @format = format
    ensure_directory_exists
  end

  def download
    return get_video_info unless can_download?

    download_with_external_tool
  end

  def download_audio_only
    return false unless can_download?

    @format = "mp3"
    download_with_external_tool
  end

  def get_video_info
    return nil unless valid_youtube_url?

    youtube_info = YoutubeInfoService.new(url: @url)
    info = youtube_info.get_video_info

    if info
      info["video_id"] = youtube_info.extract_video_id
      info["thumbnail_url"] = youtube_info.get_thumbnail_url
      info["embed_url"] = youtube_info.get_embed_url
      Rails.logger.info "Extracted YouTube info for: #{@url}"
    else
      Rails.logger.error "Failed to extract YouTube info for: #{@url}"
    end

    info
  end

  def extract_video_id
    return nil unless valid_youtube_url?
    @url[/(?:youtube\.com\/watch\?v=|youtu\.be\/|embed\/|v\/|shorts\/)([\w\-]{11})/, 1]
  end

  def can_download?
    !!get_available_tool
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
    else
      "Install yt-dlp and ffmpeg using your system’s package manager"
    end
  end

  private

  def valid_youtube_url?
    @url.present? && @url.match?(/\Ahttps?:\/\/(www\.)?(youtube\.com|youtu\.be)\//)
  end

  def ensure_directory_exists
    FileUtils.mkdir_p(@download_path) unless Dir.exist?(@download_path)
  end

  def default_download_path
    Rails.root.join("storage", "youtube_downloads")
  end

  def get_available_tool
    @available_tool ||= %w[yt-dlp youtube-dl].find do |tool|
      system("which #{tool} > /dev/null 2>&1")
    end
  end

  def build_download_command
    tool = get_available_tool
    raise "No supported tool found" unless tool

    raise "Invalid YouTube URL" unless valid_youtube_url?

    output_template = File.join(@download_path, "%(id)s.%(ext)s")
    raise "Invalid output path" unless valid_output_path?(output_template)

    cmd = [ tool ]

    case @format
    when "mp3"
      cmd += [ "--extract-audio", "--audio-format", "mp3", "--audio-quality", "192K" ]
    when "mp4"
      cmd += [ "--format", "best[ext=mp4]/best", "--merge-output-format", "mp4" ]
    end

    cmd += [ "--output", output_template, "--no-playlist", @url ]
    cmd
  end

  def download_with_external_tool
    video_id = extract_video_id
    return false unless video_id

    command = build_download_command
    stdout, stderr, status = Open3.capture3(*command)

    if status.success?
      Rails.logger.info "Download succeeded: #{stdout.strip}"
      find_downloaded_file(video_id)
    else
      Rails.logger.error "Download failed: #{stderr.strip}"
      false
    end
  end

  def valid_output_path?(path)
    # Basic sanitization: alphanumeric, dashes, dots, slashes, %()
    path.to_s.match?(/\A[\w\-\/.()%]+\.%(ext)s\z/)
  end

  def find_downloaded_file(video_id)
    extensions = @format == "mp3" ? %w[mp3] : %w[mp4 webm mkv]
    extensions.each do |ext|
      path = File.join(@download_path, "#{video_id}.#{ext}")
      return path if File.exist?(path)
    end
    false
  end
end
