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

  # Cache for Cloudflare edge and browser
  # Show pages: 1 week (content rarely changes)
  # Index pages: 1 day (may have new items)
  def cache_page(duration: 1.week)
    expires_in duration, public: true, stale_while_revalidate: 1.hour
  end

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

    @latest_news ||= News.includes(:scholar).for_domain_id(@domain.id).published.order(published_at: :desc).limit(5)
  end

  def set_default_meta_tags
    site_name = @domain&.title.presence || request.host
    # Per-tenant description lives on the Domain record; fall back to a
    # locale-keyed default so non-Arabic tenants aren't forced into Arabic.
    description = @domain&.description.presence || t("meta.default_description")

    set_meta_tags(
      site: site_name,
      description: description,
      canonical: canonical_url_for,
      reverse: true,
      separator: "|",
      og: {
        site_name: site_name,
        type: "website",
        locale: "ar_AR",
        url: canonical_url_for,
        description: description
      },
      twitter: {
        card: "summary_large_image",
        description: description
      }
    )
  end

  def noindex_page?
    (params[:page].present? && params[:page].to_i > 1) ||
      params[:q].present? ||
      params[:scholars].present? ||
      params[:content_types].present?
  end

  def set_noindex_meta_tags(empty: false)
    set_meta_tags(noindex: true, follow: true) if noindex_page? || empty
  end

  def canonical_url_for
    # Sitemap URLs are generated per current host/domain, so the matching page
    # must self-canonicalize on that same host. Do not canonicalize 3ilm.org
    # pages to scholar subdomains or external domains.
    request.original_url.split(/[?#]/).first
  end
  helper_method :canonical_url_for

  def seo_text(value, fallback:, limit: MetaTags.config.description_limit)
    text = if value.respond_to?(:to_plain_text)
      value.to_plain_text
    else
      ActionController::Base.helpers.strip_tags(value.to_s)
    end
    text = text.squish
    text = fallback if text.blank?
    text.truncate(limit)
  end

  def set_collection_meta_tags(content_type)
    metadata = collection_seo_metadata.fetch(content_type.to_s)
    set_meta_tags(
      title: metadata[:title],
      description: metadata[:description],
      canonical: canonical_url_for,
      og: {
        title: metadata[:title],
        description: metadata[:description],
        type: "website",
        url: canonical_url_for
      },
      twitter: {
        title: metadata[:title],
        description: metadata[:description]
      }
    )
  end

  def collection_seo_metadata
    site_name = @domain&.title.presence || "العلم"
    {
      "home" => {
        title: "العلم - مكتبة صوتية ومقروءة للعلم الشرعي",
        description: "موقع العلم مكتبة شرعية تجمع الكتب والمحاضرات والدروس والسلاسل العلمية والفتاوى والمقالات بصيغة سهلة للبحث والاستماع والقراءة."
      },
      "article" => {
        title: "المقالات الشرعية - #{site_name}",
        description: "تصفح المقالات الشرعية المنشورة في #{site_name} مع مواد علمية مرتبة وسهلة البحث."
      },
      "book" => {
        title: "الكتب الشرعية - #{site_name}",
        description: "تصفح الكتب الشرعية في #{site_name} مع روابط القراءة أو التحميل ومواد علمية موثوقة."
      },
      "lecture" => {
        title: "الخطب والمحاضرات والفوائد - #{site_name}",
        description: "استمع إلى الخطب والمحاضرات والفوائد الصوتية والمرئية في #{site_name} مصنفة وقابلة للبحث."
      },
      "series" => {
        title: "السلاسل العلمية والدروس - #{site_name}",
        description: "تصفح السلاسل العلمية والدروس المرتبة في #{site_name} مع روابط الدروس والاستماع والمتابعة."
      },
      "fatwa" => {
        title: "الفتاوى الشرعية - #{site_name}",
        description: "ابحث في الفتاوى الشرعية في #{site_name} حسب الموضوع والعنوان والشيخ مع إجابات واضحة ومفهرسة."
      },
      "news" => {
        title: "الأخبار والإعلانات - #{site_name}",
        description: "آخر الأخبار والإعلانات والتحديثات المنشورة في #{site_name}."
      }
    }
  end

  def slug_mismatch?(param_key, record)
    value = params[param_key]
    return false if value.nil?
    value != record.slug && value != record.id.to_s
  end

  def ilm_domain
    Rails.cache.fetch("ilm_domain", expires_in: 1.hour) do
      Domain.find_by(name: Domain::ILM_NAME)
    end
  end
end
