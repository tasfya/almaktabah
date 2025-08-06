class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include BreadcrumbHelper
  include Pagy::Backend

  before_action :latest_news
  before_action :setup_breadcrumbs
  before_action :set_domain
  layout :determine_layout
  before_action :latest_news

  protected

  def set_domain
    @domain = Domain.find_by_host(request.host)
    if @domain&.logo.present?
      @logo_url = url_for(@domain.logo)
    else
      @logo_url = ActionController::Base.helpers.asset_path("logo.png")
    end
  end

  def determine_layout
    return @domain.layout_name if @domain&.layout_name.present?
    "application"
  end

  def setup_breadcrumbs
    # Cleanup old breadcrumbs and set limits
    cleanup_old_breadcrumbs(24) # Remove breadcrumbs older than 24 hours
    set_breadcrumb_limits(8) # Keep max 8 breadcrumbs

    # Reset breadcrumbs on home page
    if (controller_name == "home" && action_name == "index") || controller_path.start_with?("devise/")
      reset_breadcrumbs
    end
  end

  def latest_news
    @latest_news ||= News.for_domain_id(@domain.id).published.order(published_at: :desc).limit(5)
  end
end
