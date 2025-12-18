# frozen_string_literal: true

class TypesenseSearchService
  SearchResult = Struct.new(:grouped_hits, :facets, :total_found, :page, :per_page, keyword_init: true) do
    def total_pages
      return 0 if per_page.zero?

      (total_found.to_f / per_page).ceil
    end

    def empty?
      total_found.zero?
    end

    def has_results_for?(type)
      grouped_hits[type.to_sym]&.any?
    end
  end
end
