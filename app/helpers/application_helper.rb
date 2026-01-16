module ApplicationHelper
  include Pagy::Frontend
  include FaviconHelper
  include SeoHelper

  CONTENT_TYPE_ROUTES = {
    "book" => :books_path,
    "lecture" => :lectures_path,
    "series" => :series_index_path,
    "fatwa" => :fatwas_path,
    "news" => :news_index_path,
    "article" => :articles_path
  }.freeze

  CONTENT_TYPE_NAV_KEYS = {
    "book" => "books",
    "lecture" => "lectures",
    "series" => "scientific_series",
    "fatwa" => "fatwas",
    "news" => "news",
    "article" => "articles"
  }.freeze

  def available_content_types
    @available_content_types ||= DomainContentTypesService.for_domain(@domain&.id)
  end

  def content_type_path(type)
    route_method = CONTENT_TYPE_ROUTES[type]
    return root_path unless route_method

    send(route_method)
  end

  def content_type_nav_key(type)
    CONTENT_TYPE_NAV_KEYS[type] || type.to_s
  end

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

    text.downcase.gsub(/[^ا-ي0-9\s]/i, "").gsub(/\s+/, "-")
  end

  def active_link_class(path, base_class = "sidebar-link")
    current_path = request.path
    if path == root_path
      return "#{base_class} active" if current_path == root_path
      return base_class
    end

    if current_path.start_with?(path)
      "#{base_class} active"
    else
      base_class
    end
  end


  def resource_share_url(resource)
    case resource
    when Lesson
      series = resource.series
      scholar = series&.scholar
      return polymorphic_url(series, scholar_id: scholar.to_param) if series && scholar
    when Lecture
      scholar = resource.respond_to?(:scholar) ? resource.scholar : nil
      return polymorphic_url(resource, scholar_id: scholar.to_param, kind: resource.kind.presence) if scholar
    else
      scholar = resource.respond_to?(:scholar) ? resource.scholar : nil
      return polymorphic_url(resource, scholar_id: scholar.to_param) if scholar
    end
    polymorphic_url(resource)
  end

  def direct_download_url(attachment)
    return nil unless attachment&.attached?

    if attachment.service.respond_to?(:url) && attachment.service.name == :public_media_hetzner
      attachment.url
    else
      rails_blob_url(attachment, disposition: "attachment")
    end
  end
end
