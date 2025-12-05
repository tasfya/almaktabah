  class SearchController < ApplicationController
    include Filterable
    before_action :setup_search_breadcrumbs

    def index
      @query = params[:q]&.strip
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
        page: params[:page],
        per_page: 5
      }
    end
  end
