  class SearchController < ApplicationController
    include SearchableController
    before_action :setup_search_breadcrumbs


    private

    def setup_search_breadcrumbs
      breadcrumb_for(t("navigation.search"), search_path)
    end
  end
