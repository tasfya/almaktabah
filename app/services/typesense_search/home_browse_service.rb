# frozen_string_literal: true

module TypesenseSearch
  # Browse mode for home page: returns N items from each collection, grouped
  class HomeBrowseService
    def initialize(domain_id: nil, content_types: [], scholars: [], per_page: 6)
      @domain_id = domain_id
      @content_types = normalize_content_types(content_types)
      @scholars = Array(scholars).map(&:to_s).reject(&:blank?)
      @per_page = per_page
      @filter_builder = FilterBuilder.new(
        domain_id: @domain_id,
        scholars: @scholars,
        content_types: @content_types
      )
    end

    def call
      response = perform_search
      build_result(response)
    rescue ::Typesense::Error => e
      Rails.logger.error("Typesense browse error: #{e.message}")
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
      selected = selected_collections
      searches = Collections::NAMES.map do |collection|
        search = {
          "collection" => collection,
          "query_by" => Collections::SEARCHABLE_FIELDS[collection],
          "facet_by" => Collections::FACET_FIELDS,
          "filter_by" => @filter_builder.build
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
            "per_page" => 0
          }
        end
      end

      searches
    end

    def selected_collections
      return Collections::NAMES if @content_types.empty?

      Collections::NAMES.select { |c| @content_types.include?(c.downcase) }
    end

    def common_params
      {
        "q" => "*",
        "sort_by" => "created_at_ts:desc",
        "page" => 1,
        "per_page" => @per_page,
        "highlight_full_fields" => "title,description,name,content_text"
      }
    end

    def build_result(response)
      grouped_hits = extract_grouped_hits(response)
      selected_indices = selected_collections.map { |c| Collections.index_for(c) }.to_set
      facets = FacetMerger.new(
        response,
        selected_indices: selected_indices,
        scholars_filtered: @scholars.present?,
        content_types_filtered: @content_types.present?
      ).merge

      SearchResult.new(
        grouped_hits: grouped_hits,
        facets: facets,
        total_found: calculate_total(response),
        page: 1,
        per_page: @per_page
      )
    end

    def extract_grouped_hits(response)
      results = response["results"]
      selected_collections.to_h do |collection|
        index = Collections.index_for(collection)
        hits = results[index]["hits"]&.map { |h| SearchHit.new(h, collection.downcase) } || []
        [ Collections.key_for(collection), hits ]
      end
    end

    def calculate_total(response)
      selected_collections.sum do |collection|
        index = Collections.index_for(collection)
        response["results"][index]["found"] || 0
      end
    end

    def normalize_content_types(content_types)
      Array(content_types).map(&:to_s).map(&:downcase).reject(&:blank?)
    end

    def empty_result
      empty_hits = Collections::KEYS.values.each_with_object({}) { |key, hash| hash[key] = [] }
      SearchResult.new(grouped_hits: empty_hits, facets: {}, total_found: 0, page: 1, per_page: @per_page)
    end
  end
end
