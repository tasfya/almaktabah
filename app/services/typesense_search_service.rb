# frozen_string_literal: true

class TypesenseSearchService
  CONTENT_COLLECTIONS = %w[News Fatwa Lecture Lesson Series Article Book].freeze

  # Maps content types to their plural symbol keys for results grouping
  COLLECTION_KEYS = {
    "Book" => :books,
    "Lecture" => :lectures,
    "Lesson" => :lessons,
    "Series" => :series,
    "Fatwa" => :fatwas,
    "News" => :news,
    "Article" => :articles
  }.freeze

  # Searchable fields per collection (based on actual schema)
  SEARCHABLE_FIELDS = {
    "Book" => "title,description,content_text",
    "Lecture" => "title,description,content_text",
    "Lesson" => "title,description,content_text",
    "Series" => "title,description,content_text",
    "Fatwa" => "title,content_text",  # No description field
    "News" => "title,description,content_text",
    "Article" => "title,content_text"  # No description field
  }.freeze

  # Facet fields per collection
  FACET_FIELDS = {
    "Book" => "content_type,scholar_id,media_type",
    "Lecture" => "content_type,scholar_id,media_type",
    "Lesson" => "content_type,scholar_id,media_type",
    "Series" => "content_type,scholar_id,media_type",
    "Fatwa" => "content_type,scholar_id,media_type",
    "News" => "content_type,scholar_id,media_type",
    "Article" => "content_type,scholar_id,media_type"
  }.freeze

  DEFAULT_PER_PAGE = 5
  MAX_PER_PAGE = 50

  def initialize(params = {})
    @query = params[:q].to_s.strip
    @domain_id = params[:domain_id]
    @page = [ params[:page].to_i, 1 ].max
    @per_page = [ [ params[:per_page].to_i, DEFAULT_PER_PAGE ].max, MAX_PER_PAGE ].min
    @per_page = DEFAULT_PER_PAGE if params[:per_page].to_i.zero?
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
    CONTENT_COLLECTIONS.map do |collection|
      {
        "collection" => collection,
        "query_by" => SEARCHABLE_FIELDS[collection],
        "facet_by" => FACET_FIELDS[collection],
        "filter_by" => content_filter_string
      }
    end
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

  def content_filter_string
    return "" if @domain_id.blank?

    "domain_ids:=[#{@domain_id}]"
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

    # Results are in same order as searches
    CONTENT_COLLECTIONS.each_with_index.each_with_object({}) do |(collection, index), grouped|
      key = COLLECTION_KEYS[collection]
      grouped[key] = extract_hits_at(results, index, collection.downcase)
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
