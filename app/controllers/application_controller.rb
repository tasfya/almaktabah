class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :setup_breadcrumbs
  before_action :set_domain
  before_action :latest_news
  after_action { pagy_headers_merge(@pagy) if @pagy }
  include BreadcrumbHelper
  include Pagy::Backend
  include ViewResolver

  protected

  def set_domain
    @domain = Domain.find_by_host(request.host)
    if @domain&.logo.present?
      @logo_url = url_for(@domain.logo)
    else
      @logo_url = ActionController::Base.helpers.asset_path("logo.png")
    end
  end

  def setup_breadcrumbs
    cleanup_old_breadcrumbs(24) # Remove breadcrumbs older than 24 hours
    set_breadcrumb_limits(8) # Keep max 8 breadcrumbs

    if (controller_name == "home" && action_name == "index") || controller_path.start_with?("devise/")
      reset_breadcrumbs
    end
  end

  def latest_news
    return unless @domain

    @latest_news ||= News.for_domain_id(@domain.id).published.order(published_at: :desc).limit(5)
  end
end
