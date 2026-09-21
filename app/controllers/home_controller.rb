# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    cache_page(duration: 1.day)
    set_collection_meta_tags("home")

    @query = params[:q].is_a?(String) ? params[:q].strip.presence : nil
    @search_filters = { scholars: params[:scholars], content_types: params[:content_types] }
    @all_content_types = TypesenseSearch::Collections::NAMES

    result = if @query.present?
      TypesenseSearch::MixedSearchService.new(
        query: @query,
        domain_id: @domain&.id,
        content_types: params[:content_types],
        scholars: params[:scholars],
        page: params[:page],
        per_page: 21
      ).call
    else
      TypesenseSearch::HomeBrowseService.new(
        domain_id: @domain&.id,
        content_types: params[:content_types],
        scholars: params[:scholars],
        per_page: 6
      ).call
    end

    @results = result.grouped_hits
    @facets = result.facets
    @total_results = result.total_found
    @page = result.page
    @per_page = result.per_page
    @total_pages = result.total_pages

    set_noindex_meta_tags
    render "search/index"
  end
end
