module ApplicationHelper
  include Pagy::Frontend

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

  def resource_title(resource)
    case resource
    when Lesson
      resource.full_title
    else
      resource.title
    end
  end
end
