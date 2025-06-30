module ApplicationHelper
  include Pagy::Frontend

  def format_date(date, format = :long)
    return unless date.present?

    l(date, format: format)
  end

  def site_info
    # TODO: Replace with actual site information
    {
      support_email: "info@almaktabah.com",
      facebook_url: "https://facebook.com/myapp",
      contact_phone: "+212 600 000 000",
      twitter_url: "https://twitter.com/myapp"
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
end
