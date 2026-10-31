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
    return 0 if count.zero?
    (count.to_f / URLS_PER_SITEMAP).ceil
  end

  def compute_latest_updated_at(type)
    return @domain.updated_at if type.to_sym == :listings
    return @domain.updated_at if type.to_sym == :static

    config = CONTENT_TYPES[type.to_sym]
    return nil unless config && config[:model]

    base_scope_for(type).maximum(:updated_at)
  end

  def base_scope_for(type)
    canonical_here(published_scope_for(type), type)
      .includes(CONTENT_TYPES[type.to_sym][:includes])
      .order(updated_at: :desc)
  end

  def published_scope_for(type)
    config = CONTENT_TYPES[type.to_sym]
    scope = config[:model].published
    config[:domain_scoped] ? scope.for_domain_id(@domain.id) : scope
  end

  # Keeps the records whose canonical URL is on this domain, mirroring
  # ApplicationController#canonical_domain_for: the scholar's default domain,
  # else the ilm domain, else the requesting domain.
  def canonical_here(scope, type)
    scholars = Scholar.arel_table
    here = scholars[:id].eq(nil).or(scholars[:default_domain_id].eq(@domain.id))
    here = here.or(scholars[:default_domain_id].eq(nil)) if fallback_canonical_here?
    scope.left_joins(type.to_sym == :lessons ? { series: :scholar } : :scholar).where(here)
  end

  def fallback_canonical_here?
    ilm = Domain.find_by(name: Domain::ILM_NAME)
    ilm.nil? || ilm.id == @domain.id
  end

  def listing_urls
    SitemapsHelper::LISTING_LOCS.filter_map do |type|
      { loc: type } if published_scope_for(type).exists?
    end
  end

  def static_urls
    [ { loc: :root }, { loc: :about } ]
  end
end
