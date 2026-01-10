# frozen_string_literal: true

module TypesenseSearch
  # Search within a single collection (for collection listing pages)
  class CollectionSearchService
    def initialize(collection:, query: nil, domain_id: nil, scholars: [], page: 1, per_page: Collections::DEFAULT_PER_PAGE)
      @collection = collection.to_s.capitalize
      @query = query.to_s.strip.presence
      @domain_id = domain_id
      @scholars = Array(scholars).map(&:to_s).reject(&:blank?)
      @page = [ page.to_i, 1 ].max
      @per_page = per_page.to_i.clamp(1, Collections::MAX_PER_PAGE)
      @filter_builder = FilterBuilder.new(
        domain_id: @domain_id,
        scholars: @scholars
      )
    end

    def call
      response = perform_search
      build_result(response)
    rescue ::Typesense::Error => e
      Rails.logger.error("Typesense collection search error: #{e.message}")
      empty_result
    end

    private

    def perform_search
      Client.multi_search.perform(
        { searches: build_searches },
        common_params
      )
    end

    def build_searches
      searches = [ main_search ]

      # Disjunctive faceting: when filtering by scholars, we need a separate query
      # WITHOUT the scholar filter to get accurate scholar facet counts. This lets
      # users see counts for other scholars they could add to their selection.
      if @scholars.present?
        searches << {
          "collection" => @collection,
          "query_by" => Collections::SEARCHABLE_FIELDS[@collection],
          "facet_by" => "scholar_name",
          "filter_by" => @filter_builder.without_scholars,
          "per_page" => 0
        }
      end

      searches
    end

    def main_search
      {
        "collection" => @collection,
        "query_by" => Collections::SEARCHABLE_FIELDS[@collection],
        "facet_by" => Collections::FACET_FIELDS,
        "filter_by" => @filter_builder.build
      }
    end

    def common_params
      {
        "q" => effective_query,
        "sort_by" => sort_order,
        "page" => @page,
        "per_page" => @per_page,
        "highlight_full_fields" => "title,description,name,content_text"
      }
    end

    def effective_query
      @query.presence || "*"
    end

    def sort_order
      @query.present? ? "_text_match:desc" : "created_at_ts:desc"
    end

    def build_result(response)
      results = response["results"] || []
      main_result = results[0] || {}
      hits = main_result["hits"]&.map { |h| SearchHit.new(h, @collection.downcase) } || []

      facets = if @scholars.present?
        # Main result facets (excluding scholar_name since it's filtered)
        main_facets = extract_facets(main_result).except("scholar_name")
        # Scholar facets from extra query (without scholar filter for disjunctive counts)
        scholar_facets = extract_facets(results[1] || {})
        main_facets.merge(scholar_facets)
      else
        extract_facets(main_result)
      end

      key = Collections.key_for(@collection)
      SearchResult.new(
        grouped_hits: { key => hits },
        facets: facets,
        total_found: main_result["found"] || 0,
        page: @page,
        per_page: @per_page
      )
    end

    def extract_facets(result)
      (result["facet_counts"] || []).to_h do |facet|
        counts = facet["counts"].map { |c| { value: c["value"], count: c["count"] } }
                                .sort_by { |f| -f[:count] }
        [ facet["field_name"], counts ]
      end
    end

    def empty_result
      key = Collections.key_for(@collection)
      SearchResult.new(grouped_hits: { key => [] }, facets: {}, total_found: 0, page: 1, per_page: @per_page)
    end
  end
end
