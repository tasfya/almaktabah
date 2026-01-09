# frozen_string_literal: true

class TypesenseSearchService
  CONTENT_COLLECTIONS = %w[News Fatwa Lecture Series Article Book].freeze

  # Maps content types to their plural symbol keys for results grouping
  COLLECTION_KEYS = {
    "Book" => :books,
    "Lecture" => :lectures,
    "Series" => :series,
    "Fatwa" => :fatwas,
    "News" => :news,
    "Article" => :articles
  }.freeze

  # Searchable fields per collection (based on actual schema)
  SEARCHABLE_FIELDS = {
    "Book" => "title,description,content_text,scholar_name",
    "Lecture" => "title,description,content_text,scholar_name",
    "Series" => "title,description,content_text,scholar_name",
    "Fatwa" => "title,content_text,scholar_name",  # No description field
    "News" => "title,description,content_text,scholar_name",
    "Article" => "title,content_text,scholar_name"  # No description field
  }.freeze

  FACET_FIELDS = "content_type,scholar_name,media_type"

  DEFAULT_PER_PAGE = 6
  MAX_PER_PAGE = 50

  def initialize(params = {})
    @query = params[:q].to_s.strip
    @domain_id = params[:domain_id]
    @content_types = normalize_content_types(params[:content_types])
    @scholars = Array(params[:scholars]).map(&:to_s).reject(&:blank?)
    @page = [ params[:page].to_i, 1 ].max
    @per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i.clamp(1, MAX_PER_PAGE) : DEFAULT_PER_PAGE
  end

  def search
    response = perform_multi_search
    build_result(response)
  rescue Typesense::Error => e
    Rails.logger.error("Typesense search error: #{e.message}")
    empty_result
  end

  def browsing?
    @query.blank?
  end

  private

  def client
    @client ||= Typesense::Client.new(Typesense.configuration)
  end

  def perform_multi_search
    client.multi_search.perform(
      { searches: build_searches },
      common_params
    )
  end

  def build_searches
    selected = selected_collections
    searches = collections_to_search.map do |collection|
      search = {
        "collection" => collection,
        "query_by" => SEARCHABLE_FIELDS[collection],
        "facet_by" => FACET_FIELDS,
        "filter_by" => build_filter_string
      }
      # Unselected collections: only fetch facet counts, no hits
      search["per_page"] = 0 unless selected.include?(collection)
      search
    end

    # For disjunctive scholar faceting: add queries without scholar filter
    if @scholars.present?
      selected.each do |collection|
        searches << {
          "collection" => collection,
          "query_by" => SEARCHABLE_FIELDS[collection],
          "facet_by" => "scholar_name",
          "filter_by" => build_filter_string_without_scholars,
          "per_page" => 0
        }
      end
    end

    searches
  end

  # Always search all collections to get accurate facet counts
  def collections_to_search
    CONTENT_COLLECTIONS
  end

  def selected_collections
    return CONTENT_COLLECTIONS if @content_types.empty?

    CONTENT_COLLECTIONS.select { |c| @content_types.include?(c.downcase) }
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
    browsing? ? "*" : @query
  end

  def sort_order
    browsing? ? "created_at_ts:desc" : "_text_match:desc"
  end

  def build_filter_string
    filters = []
    filters << "domain_ids:=[#{@domain_id}]" if @domain_id.present?
    filters << "scholar_name:=[#{@scholars.map { |n| "`#{sanitize_filter_value(n)}`" }.join(',')}]" if @scholars.present?
    filters.join(" && ")
  end

  def build_filter_string_without_scholars
    filters = []
    filters << "domain_ids:=[#{@domain_id}]" if @domain_id.present?
    # Include content_types so scholar counts reflect the current content type filter
    filters << build_content_type_filter if @content_types.present?
    filters.join(" && ")
  end

  def build_content_type_filter
    return nil if @content_types.empty?

    values = @content_types.map { |t| "`#{t}`" }.join(",")
    "content_type:=[#{values}]"
  end

  def normalize_content_types(content_types)
    Array(content_types).map(&:to_s).map(&:downcase).reject(&:blank?)
  end

  def sanitize_filter_value(value)
    value.delete("`")
  end

  def build_result(response)
    grouped_hits = group_hits_by_type(response)
    facets = merge_facets(response)
    total_found = calculate_total_found(response)

    SearchResult.new(
      grouped_hits: grouped_hits,
      facets: facets,
      total_found: total_found,
      page: @page,
      per_page: @per_page
    )
  end

  def calculate_total_found(response)
    # Only count results from selected content types
    selected_collections.sum do |collection|
      index = CONTENT_COLLECTIONS.index(collection)
      response["results"][index]["found"] || 0
    end
  end

  def group_hits_by_type(response)
    results = response["results"]

    # Only include hits from selected content types (but all collections were searched for facets)
    selected_collections.to_h do |collection|
      index = CONTENT_COLLECTIONS.index(collection)
      [ COLLECTION_KEYS[collection], extract_hits_at(results, index, collection.downcase) ]
    end
  end

  def extract_hits_at(results, index, content_type)
    result = results[index]
    return [] unless result&.dig("hits")

    result["hits"].map { |hit| SearchHit.new(hit, content_type) }
  end

  def merge_facets(response)
    merged = Hash.new { |h, k| h[k] = Hash.new(0) }
    main_results_count = CONTENT_COLLECTIONS.size
    selected_indices = selected_collections.map { |c| CONTENT_COLLECTIONS.index(c) }.to_set

    response["results"].each_with_index do |result, index|
      is_extra_scholar_query = index >= main_results_count
      is_selected_collection = selected_indices.include?(index)

      result["facet_counts"]&.each do |facet|
        field = facet["field_name"]
        next unless include_facet?(field, is_extra_scholar_query, is_selected_collection)

        facet["counts"].each do |count|
          merged[field][count["value"]] += count["count"]
        end
      end
    end

    merged.transform_values do |counts|
      counts.map { |value, count| { value: value, count: count } }
            .sort_by { |f| -f[:count] }
    end
  end

  # Determines whether to include a facet based on filter state and query type.
  # Scholar facets need special handling for disjunctive counts.
  def include_facet?(field, is_extra_scholar_query, is_selected_collection)
    return true unless field == "scholar_name"

    # When scholars filter active: use extra disjunctive queries only
    return is_extra_scholar_query if @scholars.present?

    # When content_types filter active: use only selected collections
    return is_selected_collection if @content_types.present?

    true
  end

  def empty_result
    empty_hits = COLLECTION_KEYS.values.each_with_object({}) { |key, hash| hash[key] = [] }

    SearchResult.new(
      grouped_hits: empty_hits,
      facets: {},
      total_found: 0,
      page: 1,
      per_page: @per_page
    )
  end
end
