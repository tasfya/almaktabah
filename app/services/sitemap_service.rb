# frozen_string_literal: true

class SitemapService
  URLS_PER_SITEMAP = 50_000

  CONTENT_TYPES = {
    articles: { model: Article, domain_scoped: true, includes: :scholar },
    books: { model: Book, domain_scoped: true, includes: :scholar },
    lectures: { model: Lecture, domain_scoped: true, includes: :scholar },
    series: { model: Series, domain_scoped: true, includes: :scholar },
    fatwas: { model: Fatwa, domain_scoped: true, includes: :scholar },
    news: { model: News, domain_scoped: true, includes: nil },
    lessons: { model: Lesson, domain_scoped: true, includes: { series: :scholar } },
    listings: { model: nil, domain_scoped: false, includes: nil },
    static: { model: nil, domain_scoped: false, includes: nil }
  }.freeze

  def initialize(domain)
    raise ArgumentError, "domain is required" if domain.nil?
    @domain = domain
  end

  def content_type_pages
    CONTENT_TYPES.keys.flat_map do |type|
      (1..page_count(type)).map { |page| { type: type, page: page } }
    end
  end

  def urls_for(type, page: 1)
    return listing_urls if type.to_sym == :listings
    return static_urls if type.to_sym == :static

    config = CONTENT_TYPES[type.to_sym]
    return [] unless config && config[:model]

    scope = base_scope_for(type)
    scope.offset((page - 1) * URLS_PER_SITEMAP).limit(URLS_PER_SITEMAP)
  end

  def page_count(type)
    @page_count_cache ||= {}
    @page_count_cache[type.to_sym] ||= compute_page_count(type)
  end

  def latest_updated_at(type)
    @latest_updated_at_cache ||= {}
    return @latest_updated_at_cache[type.to_sym] if @latest_updated_at_cache.key?(type.to_sym)

    @latest_updated_at_cache[type.to_sym] = compute_latest_updated_at(type)
  end

  private

  def compute_page_count(type)
    return 1 if type.to_sym == :listings
    return 1 if type.to_sym == :static

    config = CONTENT_TYPES[type.to_sym]
    return 0 unless config && config[:model]

    count = base_scope_for(type).count
    (count.to_f / URLS_PER_SITEMAP).ceil.clamp(1..)
  end

  def compute_latest_updated_at(type)
    return @domain.updated_at if type.to_sym == :listings
    return @domain.updated_at if type.to_sym == :static

    config = CONTENT_TYPES[type.to_sym]
    return nil unless config && config[:model]

    base_scope_for(type).maximum(:updated_at)
  end

  def base_scope_for(type)
    config = CONTENT_TYPES[type.to_sym]
    model = config[:model]
    includes = config[:includes]

    scope = model.published
    scope = scope.for_domain_id(@domain.id) if config[:domain_scoped]
    scope = scope.includes(includes) if includes.present?
    scope.order(updated_at: :desc)
  end

  LISTING_TYPES = %i[articles books lectures series fatwas news].freeze

  def listing_urls
    LISTING_TYPES.filter_map do |type|
      { loc: type } if base_scope_for(type).exists?
    end
  end

  def static_urls
    [ { loc: :root }, { loc: :about } ]
  end
end
