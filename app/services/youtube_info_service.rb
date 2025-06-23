require "net/http"
require "uri"
require "json"

class YoutubeInfoService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :url

  def initialize(url:)
    @url = url
  end

  def get_video_info
    return nil unless valid_youtube_url?

    begin
      video_id = extract_video_id
      return nil unless video_id

      # Use YouTube's oEmbed API to get basic info
      oembed_url = "https://www.youtube.com/oembed?url=#{CGI.escape(@url)}&format=json"

      uri = URI(oembed_url)
      response = Net::HTTP.get_response(uri)

      if response.code == "200"
        # Handle encoding for JSON response
        response_body = safe_encode_text(response.body) || response.body
        info = JSON.parse(response_body)

        # Ensure all text fields are properly encoded
        info["title"] = safe_encode_text(info["title"]) if info["title"]
        info["author_name"] = safe_encode_text(info["author_name"]) if info["author_name"]

        # Enhance with additional info from the page
        page_info = scrape_page_info(video_id)
        info.merge!(page_info) if page_info

        info
      else
        Rails.logger.error "Failed to get YouTube info: #{response.code} #{response.message}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "Error getting YouTube info: #{e.message}"
      nil
    end
  end

  def extract_video_id
    return nil unless valid_youtube_url?

    # Extract video ID from various YouTube URL formats
    patterns = [
      /(?:youtube\.com\/watch\?v=)([a-zA-Z0-9_-]{11})/,
      /(?:youtu\.be\/)([a-zA-Z0-9_-]{11})/,
      /(?:youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
      /(?:youtube\.com\/v\/)([a-zA-Z0-9_-]{11})/,
      /(?:youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})/
    ]

    patterns.each do |pattern|
      match = @url.match(pattern)
      return match[1] if match
    end

    nil
  end

  def get_thumbnail_url(quality: "maxresdefault")
    video_id = extract_video_id
    return nil unless video_id

    # YouTube thumbnail URL format
    "https://img.youtube.com/vi/#{video_id}/#{quality}.jpg"
  end

  def get_embed_url
    video_id = extract_video_id
    return nil unless video_id

    "https://www.youtube.com/embed/#{video_id}"
  end

  private

  def valid_youtube_url?
    return false unless @url.present?
    @url.include?("youtube.com") || @url.include?("youtu.be")
  end

  def scrape_page_info(video_id)
    begin
      page_url = "https://www.youtube.com/watch?v=#{video_id}"
      uri = URI(page_url)

      response = Net::HTTP.get_response(uri)
      return nil unless response.code == "200"

      # Get the HTML content and handle encoding properly
      html = response.body

      # Try to detect and fix encoding
      html = safe_encode_text(html) || html.force_encoding("UTF-8").scrub("?")

      info = {}

      # Extract duration from page meta tags
      duration_match = html.match(/"lengthSeconds":"(\d+)"/)
      info["duration"] = duration_match[1].to_i if duration_match

      # Extract view count
      view_match = html.match(/"viewCount":"(\d+)"/)
      info["view_count"] = view_match[1].to_i if view_match

      # Extract upload date
      date_match = html.match(/"publishDate":"([^"]+)"/)
      info["upload_date"] = date_match[1] if date_match

      # Extract description with proper encoding handling
      desc_match = html.match(/"shortDescription":"([^"]*)"/)
      if desc_match
        description = desc_match[1].gsub(/\\n/, "\n").gsub(/\\"/, '"')
        # Ensure proper UTF-8 encoding
        description = safe_encode_text(description)
        info["description"] = description if description && description.present?
      end

      info
    rescue StandardError => e
      Rails.logger.warn "Failed to scrape page info: #{e.message}"
      nil
    end
  end

  # Helper method to safely handle text encoding
  def safe_encode_text(text)
    return nil unless text.present?

    text_str = text.to_s

    # If it's already valid UTF-8, return as is
    if text_str.encoding == Encoding::UTF_8 && text_str.valid_encoding?
      return text_str
    end

    # Try different encoding approaches
    begin
      # First, try to detect if it's actually UTF-8 with wrong encoding label
      if text_str.encoding == Encoding::ASCII_8BIT
        utf8_attempt = text_str.force_encoding("UTF-8")
        return utf8_attempt if utf8_attempt.valid_encoding?
      end

      # Convert to UTF-8 with replacement characters for invalid bytes
      text_str.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
      Rails.logger.warn "Encoding issue with text in YoutubeInfoService: #{e.message}"
      # Fallback: scrub invalid characters
      text_str.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?").scrub("?")
    rescue => e
      Rails.logger.warn "Unexpected encoding error in YoutubeInfoService: #{e.message}"
      # Last resort: use only ASCII characters
      text_str.gsub(/[^\x00-\x7F]/, "?")
    end
  end
end
