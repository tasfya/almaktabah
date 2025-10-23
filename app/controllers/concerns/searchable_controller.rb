module SearchableController
  extend ActiveSupport::Concern

  included do
    before_action :initialize_search_params, only: [ :index, :search ]
  end

  def index
    # Always use Typesense - either for search or default content
    perform_typesense_query
    @all_content_types = default_content_types
    @domain_scholars = get_domain_scholars
    render :index
  end

  def search
    perform_typesense_query
    @domain_scholars = get_domain_scholars
    respond_to do |format|
      format.turbo_stream { render_search_results }
      format.html { render :index }
    end
  end

  private

  def perform_typesense_query
    @search_service = TypesenseSearchService.new(
      query: search_query_or_default,
      filters: build_search_filters,
      domain: @domain,
      default_content_types: default_content_types,
      default_sort: default_sort_order
    )

    result = @search_service.search
    @search_results = result.results
    @facets = result.facet_counts
    @total_hits = result.total_hits
    @total_found = result.total_found
    @is_search_mode = search_query_present?
  end

  def search_query_or_default
    # Use actual search query if present, otherwise wildcard for "browse all"
    search_query_present? ? @search_query : "*"
  end

  def build_search_filters
    base_filters = {
      domain_id: @domain.id,
      content_types: determine_content_types,
      per_page: search_params[:per_page] || default_per_page,
      page: search_params[:page] || 1
    }

    # Add user-selected filters if in search mode
    if search_query_present?
      base_filters.merge!(extract_user_filters)
    end

    base_filters
  end

  def determine_content_types
    # If user hasn't expanded search, use controller's default types
    if @search_filters[:expand_search] || @search_filters[:content_types].present?
      @search_filters[:content_types]
    else
      default_content_types
    end
  end

  def default_content_types
    [ "news", "fatwa", "lecture", "series", "book" ]
  end

  def default_sort_order
    # Override in each controller for different default sorting
    "published_at:desc"
  end

  def default_per_page
    if determine_content_types.size > 1
      6 # For unified search, show fewer results per type
    else
      20
    end
  end

  def search_query_present?
    @search_query.present? && @search_query != "*"
  end

  def initialize_search_params
    @search_query = search_params[:q]&.strip
    @search_filters = extract_search_filters
  end

  def extract_search_filters
    {
      content_types: search_params[:content_types]&.reject(&:blank?),
      scholars: search_params[:scholars]&.reject(&:blank?),
      media_types: search_params[:media_types]&.reject(&:blank?),
      topics: search_params[:topics]&.reject(&:blank?),
      duration_range: search_params[:duration_range],
      expand_search: search_params[:expand_search] == "true",
      per_page: search_params[:per_page],
      page: search_params[:page]
    }
  end

  def extract_user_filters
    {
      scholars: @search_filters[:scholars],
      media_types: @search_filters[:media_types],
      topics: @search_filters[:topics],
      duration_range: @search_filters[:duration_range]
    }.compact_blank
  end

  def render_search_results
    # Override in controllers for turbo stream responses
    render turbo_stream: turbo_stream.replace("search_results", partial: "shared/search_results")
  end

  def search_params
    params.permit(:q, :page, :per_page, :expand_search, content_types: [], scholars: [], media_types: [], topics: [])
  end

  def get_domain_scholars
    return [] unless @domain

    Scholar.for_domain_id(@domain.id).order(:first_name, :last_name)
  end
end
