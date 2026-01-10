# frozen_string_literal: true

module TypesenseSearch
  # Search mode for home page: returns mixed results sorted by relevance
  class MixedSearchService
    def initialize(query:, domain_id: nil, content_types: [], scholars: [], page: 1, per_page: Collections::DEFAULT_PER_PAGE)
      @query = query.to_s.strip
      @domain_id = domain_id
      @content_types = normalize_content_types(content_types)
      @scholars = Array(scholars).map(&:to_s).reject(&:blank?)
      @page = [ page.to_i, 1 ].max
      @per_page = per_page.to_i.clamp(1, Collections::MAX_PER_PAGE)
      @filter_builder = FilterBuilder.new(
        domain_id: @domain_id,
        scholars: @scholars,
        content_types: @content_types
      )
    end

    def call
      return empty_result if selected_collections.empty?

      hits_response = fetch_union_hits
      # Union search doesn't support facets, so we need a separate call
      facets_response = fetch_facets
      build_result(hits_response, facets_response)
    rescue ::Typesense::Error => e
      Rails.logger.error("Typesense search error: #{e.message}")
      empty_result
    end

    private

    def fetch_union_hits
      Client.multi_search.perform(
        { searches: union_searches, union: true },
        {
          "q" => @query,
          "sort_by" => "_text_match:desc",
          "page" => @page,
          "per_page" => @per_page,
          "highlight_full_fields" => "title,description,name,content_text"
        }
      )
    end

    def fetch_facets
      Client.multi_search.perform(
        { searches: facet_searches },
        { "q" => @query, "per_page" => 0 }
      )
    end

    def union_searches
      selected_collections.map do |collection|
        {
          "collection" => collection,
          "query_by" => Collections::SEARCHABLE_FIELDS[collection],
          "filter_by" => @filter_builder.build
        }
      end
    end

    def facet_searches
      selected = selected_collections
      searches = Collections::NAMES.map do |collection|
        search = {
          "collection" => collection,
          "query_by" => Collections::SEARCHABLE_FIELDS[collection],
          "facet_by" => Collections::FACET_FIELDS,
          "filter_by" => @filter_builder.build,
          "max_facet_values" => 999
        }
        search["per_page"] = 0 unless selected.include?(collection)
        search
      end

      if @scholars.present?
        selected.each do |collection|
          searches << {
            "collection" => collection,
            "query_by" => Collections::SEARCHABLE_FIELDS[collection],
            "facet_by" => "scholar_name",
            "filter_by" => @filter_builder.without_scholars,
            "per_page" => 0,
            "max_facet_values" => 999
          }
        end
      end

      searches
    end

    def selected_collections
      return Collections::NAMES if @content_types.empty?

      Collections::NAMES.select { |c| @content_types.include?(c.downcase) }
    end

    def build_result(hits_response, facets_response)
      mixed_hits = extract_mixed_hits(hits_response)
      selected_indices = selected_collections.map { |c| Collections.index_for(c) }.to_set

      facets = FacetMerger.new(
        facets_response,
        selected_indices: selected_indices,
        scholars_filtered: @scholars.present?,
        content_types_filtered: @content_types.present?,
        selected_scholars: @scholars
      ).merge

      SearchResult.new(
        grouped_hits: { mixed: mixed_hits },
        facets: facets,
        total_found: hits_response["found"] || 0,
        page: @page,
        per_page: @per_page
      )
    end

    def extract_mixed_hits(response)
      (response["hits"] || []).filter_map do |hit|
        content_type = hit.dig("document", "content_type")
        next if content_type.blank?

        SearchHit.new(hit, content_type)
      end
    end

    def normalize_content_types(content_types)
      Array(content_types).map(&:to_s).map(&:downcase).reject(&:blank?)
    end

    def empty_result
      SearchResult.new(grouped_hits: { mixed: [] }, facets: {}, total_found: 0, page: 1, per_page: @per_page)
    end
  end
end
