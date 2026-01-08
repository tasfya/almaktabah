# frozen_string_literal: true

module TypesenseListable
  extend ActiveSupport::Concern

  private

  def typesense_search(content_type: nil)
    @query = params[:q].is_a?(String) ? params[:q].strip : nil
    content_types = content_type.present? ? [ content_type ] : Array(params[:content_types]).compact_blank.presence
    @search_filters = { scholars: params[:scholars], content_types: content_types }
    @all_content_types = TypesenseSearchService::CONTENT_COLLECTIONS
    @hide_content_type_filter = content_type.present?
    @hide_section_header = content_type.present?

    @per_page = params[:per_page]&.to_i.presence || (content_type.present? ? 15 : 6)
    result = TypesenseSearchService.new(
      q: @query,
      domain_id: @domain&.id,
      content_types: content_types,
      scholars: params[:scholars],
      page: params[:page],
      per_page: @per_page
    ).search

    @facets = result.facets
    @total_results = result.total_found
    @results = result.grouped_hits
    @page = result.page
    @total_pages = result.total_pages

    render "search/index"
  end
end
