# frozen_string_literal: true

module TypesenseListable
  extend ActiveSupport::Concern

  private

  def typesense_collection_search(content_type)
    @query = params[:q].is_a?(String) ? params[:q].strip.presence : nil
    @search_filters = { scholars: params[:scholars], content_types: [ content_type ] }
    @all_content_types = TypesenseSearch::Collections::NAMES
    @hide_content_type_filter = true
    @hide_section_header = true

    result = TypesenseSearch::CollectionSearchService.new(
      collection: content_type,
      query: @query,
      domain_id: @domain&.id,
      scholars: params[:scholars],
      page: params[:page],
      per_page: params[:per_page]&.to_i.presence || 15
    ).call

    @results = result.grouped_hits
    @facets = result.facets
    @total_results = result.total_found
    @page = result.page
    @per_page = result.per_page
    @total_pages = result.total_pages

    render "search/index"
  end
end
