module ApplicationHelper
  include Pagy::Frontend
  include FaviconHelper

  def parse_integer(value)
    Integer(value) rescue nil
  end

 def parse_datetime(value)
    return nil unless value.present?
    return value if value.is_a?(DateTime) || value.is_a?(Time)
    DateTime.parse(value.to_s) rescue nil
  end

  def attach_from_url(record, attachment_name, url, content_type: nil)
    return if url.blank?

    Rails.logger.info "Enqueuing media download for #{attachment_name} from #{url} for record ##{record.id}"
    MediaDownloadJob.perform_now(
      record,
      attachment_name,
      url,
      content_type
    )
  end

  def format_date(date, format = :long)
    return unless date.present?

    l(date, format: format)
  end

  def site_info
    {
      support_email: "",
      twitter_url: "https://x.com/Moh1Rz2H3?ref",
      youtube_url: "https://www.youtube.com/@bin-ramzan"
    }
  end

  def pagy_url_for(pagy, page)
    params = request.query_parameters.merge(page: page)
    url_for(params)
  end

  def format_duration(seconds)
    return "0:00" if seconds.nil? || seconds <= 0

    minutes = seconds / 60
    remaining_seconds = seconds % 60
    format("%d:%02d", minutes, remaining_seconds)
  end

  def youtube_embed_url(url)
    return unless url.present?

    video_id = url.match(/(?:https?:\/\/)?(?:www\.)?youtu\.be\/([a-zA-Z0-9_-]+)|(?:https?:\/\/)?(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)/)
    return unless video_id

    video_id = video_id[1] || video_id[2]

    "https://www.youtube.com/embed/#{video_id}"
  end

  def slugify_arabic(text)
    return unless text.present?

    # Remove diacritics and normalize Arabic text
    text = text.to_s.strip

    # Replace spaces and underscores with hyphens
    text = text.gsub(/[\s_]+/, "-")

    # Remove consecutive hyphens
    text = text.gsub(/-+/, "-")

    # Remove leading and trailing hyphens
    text = text.gsub(/^-+|-+$/, "")

    arabic_diacritics = /[\u0610-\u061A\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]/
    text = text.gsub(arabic_diacritics, "")

    # Return the slug, fallback to random string if empty
    text.present? ? text : SecureRandom.hex(8)
  end
end
