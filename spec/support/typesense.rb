# Typesense test helpers for system specs that mock TypesenseSearchService
# responses so system tests don't require a running Typesense instance.

module TypesenseTestHelpers
  # Build a mock SearchHit from simple attributes
  def build_search_hit(type:, title:, slug: nil, **attrs)
    slug ||= title.parameterize
    document = {
      "id" => attrs[:id] || rand(1000),
      "title" => title,
      "slug" => slug,
      "description" => attrs[:description],
      "scholar_name" => attrs[:scholar_name],
      "scholar_slug" => attrs[:scholar_slug],
      "media_type" => attrs[:media_type] || "text",
      "url" => attrs[:url] || "/#{type.to_s.pluralize}/#{slug}",
      "thumbnail_url" => attrs[:thumbnail_url],
      "content_type" => type.to_s
    }.compact

    TypesenseSearchService::SearchHit.new({ "document" => document, "highlights" => [] }, type.to_s)
  end

  # Build a mock SearchResult
  def build_search_result(hits_by_type: {}, facets: nil, total: nil, page: 1, per_page: 6)
    facets ||= default_facets
    total ||= hits_by_type.values.flatten.size

    TypesenseSearchService::SearchResult.new(
      grouped_hits: hits_by_type,
      facets: facets,
      total_found: total,
      page: page,
      per_page: per_page
    )
  end

  # Stub TypesenseSearchService to return mock results
  def stub_typesense_search(result = nil, &block)
    result ||= block ? block.call : build_search_result
    allow_any_instance_of(TypesenseSearchService).to receive(:search).and_return(result)
  end

  # Build a mock mixed SearchResult for union search mode
  def build_mixed_search_result(hits:, facets: nil, total: nil, page: 1, per_page: 20)
    facets ||= default_facets
    total ||= hits.size

    TypesenseSearchService::SearchResult.new(
      grouped_hits: { mixed: hits },
      facets: facets,
      total_found: total,
      page: page,
      per_page: per_page
    )
  end

  # Empty result with zero counts
  def empty_search_result
    build_search_result(hits_by_type: {}, total: 0)
  end

  # Empty mixed result
  def empty_mixed_search_result
    build_mixed_search_result(hits: [], total: 0)
  end

  private

  def default_facets
    {
      content_types: [],
      scholars: []
    }
  end
end

RSpec.configure do |config|
  config.include TypesenseTestHelpers, type: :system
  config.include TypesenseTestHelpers, type: :controller
  config.include TypesenseTestHelpers, type: :request
end
