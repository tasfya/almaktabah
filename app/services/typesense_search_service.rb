class TypesenseSearchService
  attr_reader :query, :filters, :domain, :default_sort

  def initialize(query:, filters:, domain:, default_content_types: [], default_sort: "published_at:desc")
    @query = query.presence || "*"
    @filters = filters
    @domain = domain
    @default_content_types = default_content_types
    @default_sort = default_sort
    @typesense_client = Typesense::Client.new(Typesense.configuration)
  end

  def search
    build_search_options
    perform_search

    OpenStruct.new(
      results: @results,
      facet_counts: aggregate_facets,
      total_hits: calculate_total_hits,
      total_found: calculate_total_found
    )
  end

  private

  def aggregate_facets
    aggregated = {}

    @results.each do |content_type, result_obj|
      next unless result_obj && result_obj["facet_counts"]

      result_obj["facet_counts"].each do |facet|
        field_name = facet["field_name"]
        aggregated[field_name] ||= {}

        facet["counts"].each do |count_data|
          value = count_data["value"]
          count = count_data["count"]
          aggregated[field_name][value] ||= 0
          aggregated[field_name][value] += count
        end
      end
    end
    aggregated
  end
  def calculate_total_hits
    @results.sum { |_, result_obj| result_obj["hits"]&.length || 0 }
  end

  def calculate_total_found
    @results.sum { |_, result_obj| result_obj["found"] || 0 }
  end


  # Returns the Typesense collection name for a given content type
  def collection_name_for(content_type)
    content_type.capitalize
  end

  def build_search_options
    @search_options = {
      query_by: determine_query_fields,
      filter_by: build_filter_string,
      facet_by: "content_type,scholar_name,media_type", # Only use fields that exist in all models
      sort_by: determine_sort_order,
      per_page: @filters[:per_page] || 20,
      page: @filters[:page] || 1,
      highlight_fields: (@query == "*" ? "" : "title,description"), # No highlighting for default content
      drop_tokens_threshold: 2, # Better Arabic search
      typo_tokens_threshold: 2,
      prefix: (@query == "*" ? false : true) # Only use prefix matching for actual searches
    }
  end

  def determine_query_fields
    if @query == "*"
      # For default content loading, just use title for basic sorting
      "title"
    else
      # For actual searches, use all searchable fields
      "title,description,content_text"
    end
  end

  def build_filter_string
    filter_parts = []

    # Always filter by domain
    filter_parts << "domain_ids:#{@domain.id}"

    # Content type filtering
    if @filters[:content_types].present?
      content_filter = @filters[:content_types].map { |type| "content_type:#{type}" }.join(" || ")
      filter_parts << "(#{content_filter})"
    end

    # Only add user filters if they exist
    add_scholar_filter(filter_parts)
    add_media_type_filter(filter_parts)
    add_topic_filter(filter_parts)
    add_duration_filter(filter_parts)

    filter_parts.join(" && ")
  end

  def determine_sort_order
    # Use user-specified sort if present, otherwise use default
    if @filters[:sort_by].present?
      @filters[:sort_by]
    elsif @query == "*"
      # For default content, use controller-specified default sort
      @default_sort
    else
      # For searches, use relevance first, then recency
      "_text_match:desc,published_at:desc"
    end
  end

  def build_multi_search_queries(content_types_to_search)
    content_types_to_search.map do |content_type|
      {
        collection: collection_name_for(content_type),
        q: @query,
        **@search_options
      }
    end
  end

  def perform_search
    content_types = determine_content_types_to_search
    queries = build_multi_search_queries(content_types)

    response = @typesense_client.multi_search.perform(
      { searches: queries },
      {}
    )

    @results = {}
    content_types.each_with_index do |content_type, index|
      @results[content_type.to_sym] = response["results"][index]
    end
  rescue StandardError => e
    Rails.logger.error "Typesense multi-search failed: #{e.message}"
    @results = {}
  end

  def determine_content_types_to_search
    if @filters[:content_types].present?
      @filters[:content_types]
    else
      @default_content_types
    end
  end




  def add_scholar_filter(filter_parts)
    if @filters[:scholars].present?
      scholar_filter = @filters[:scholars].map { |scholar| "scholar_name:#{scholar}" }.join(" || ")
      filter_parts << "(#{scholar_filter})"
    end
  end

  def add_media_type_filter(filter_parts)
    if @filters[:media_types].present?
      media_filter = @filters[:media_types].map { |media| "media_type:#{media}" }.join(" || ")
      filter_parts << "(#{media_filter})"
    end
  end

  def add_topic_filter(filter_parts)
    if @filters[:topics].present?
      topic_filter = @filters[:topics].map { |topic| "topic:#{topic}" }.join(" || ")
      filter_parts << "(#{topic_filter})"
    end
  end

  def add_duration_filter(filter_parts)
    if @filters[:duration_range].present?
      # Assuming duration_range is something like "0-30" for minutes
      # This would need to be implemented based on how duration is stored
      # filter_parts << "duration_category:#{@filters[:duration_range]}"
    end
  end
end
