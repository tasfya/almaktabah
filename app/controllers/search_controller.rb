  class SearchController < ApplicationController
    before_action :setup_search_breadcrumbs

    def index
      @query = params[:q]&.strip
      @search_filters = { scholars: params[:scholars], content_types: params[:content_types] }
      @all_content_types = TypesenseSearchService::CONTENT_COLLECTIONS
      perform_typesense_search
    end

    private

    def setup_search_breadcrumbs
      breadcrumb_for(t("navigation.search"), search_path)
    end

    def perform_typesense_search
      result = TypesenseSearchService.new(search_params).search

      @facets = result.facets
      @total_results = result.total_found
      @results = result.grouped_hits  # Pass SearchHit objects directly, no DB lookup
    end

    def search_params
      {
        q: @query,
        domain_id: @domain&.id,
        content_types: params[:content_types],
        scholars: params[:scholars],
        page: params[:page],
        per_page: params[:per_page]
      }
    end
  end
