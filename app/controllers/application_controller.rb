class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include BreadcrumbHelper
  include Pagy::Backend

  before_action :most_downloaded_books
  before_action :most_viewed_books
  before_action :latest_news
  before_action :setup_breadcrumbs

  protected

  def setup_breadcrumbs
    # Cleanup old breadcrumbs and set limits
    cleanup_old_breadcrumbs(24) # Remove breadcrumbs older than 24 hours
    set_breadcrumb_limits(8) # Keep max 8 breadcrumbs

    # Reset breadcrumbs on home page
    if controller_name == "home" && action_name == "index"
      reset_breadcrumbs
    end
  end

  def most_downloaded_books
    @most_downloaded_books ||= Book.published.order(downloads: :desc).limit(5)
  end

  def most_viewed_books
    @most_viewed_books ||= Book.published.order(published_at: :desc).limit(5)
  end

  def latest_news
    @latest_news ||= News.published.order(published_at: :desc).limit(5)
  end
end
