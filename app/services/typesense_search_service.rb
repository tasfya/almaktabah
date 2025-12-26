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
    "Book" => "title,description,content_text",
    "Lecture" => "title,description,content_text",
    "Series" => "title,description,content_text",
    "Fatwa" => "title,content_text",  # No description field
    "News" => "title,description,content_text",
    "Article" => "title,content_text"  # No description field
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
    collections_to_search.map do |collection|
      {
        "collection" => collection,
        "query_by" => SEARCHABLE_FIELDS[collection],
        "facet_by" => FACET_FIELDS,
        "filter_by" => build_filter_string
      }
    end
  end

  def collections_to_search
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
    browsing? ? "published_at_ts:desc" : "_text_match:desc,published_at_ts:desc"
  end

  def build_filter_string
    filters = []
    filters << "domain_ids:=[#{@domain_id}]" if @domain_id.present?
    filters << "scholar_name:=[#{@scholars.map { |n| "`#{sanitize_filter_value(n)}`" }.join(',')}]" if @scholars.present?
    filters.join(" && ")
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
    total_found = response["results"].sum { |r| r["found"] || 0 }

    SearchResult.new(
      grouped_hits: grouped_hits,
      facets: facets,
      total_found: total_found,
      page: @page,
      per_page: @per_page
    )
  end

  def group_hits_by_type(response)
    results = response["results"]

    collections_to_search.each_with_index.to_h do |collection, index|
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

    response["results"].each do |result|
      result["facet_counts"]&.each do |facet|
        field = facet["field_name"]
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
