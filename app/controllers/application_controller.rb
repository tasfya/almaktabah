class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :setup_breadcrumbs
  before_action :set_domain
  before_action :set_default_meta_tags
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

  def set_default_meta_tags
    site_name = @domain&.title.presence || request.host
    set_meta_tags(
      site: site_name,
      description: @domain&.description.presence,
      reverse: true,
      separator: "|",
      og: {
        site_name: site_name,
        type: "website",
        locale: "ar_AR"
      },
      twitter: {
        card: "summary_large_image"
      }
    )
  end

  def noindex_page?
    (params[:page].present? && params[:page].to_i > 1) ||
      params[:q].present? ||
      params[:scholars].present? ||
      params[:content_types].present?
  end

  def set_noindex_meta_tags
    set_meta_tags(noindex: true, follow: true) if noindex_page?
  end

  def canonical_domain_for(resource)
    scholar = resource.try(:scholar)
    return @domain unless scholar
    scholar.default_domain || ilm_domain || @domain
  end

  def canonical_url_for(resource = nil)
    domain = resource ? canonical_domain_for(resource) : @domain
    if domain&.host.present? && domain.host != request.host
      "#{request.protocol}#{domain.host}#{":#{request.port}" unless request.standard_port?}#{request.path}"
    else
      request.original_url.split(/[?#]/).first
    end
  end
  helper_method :canonical_url_for

  def ilm_domain
    Rails.cache.fetch("ilm_domain", expires_in: 1.hour) do
      Domain.find_by(name: Domain::ILM_NAME)
    end
  end
end
