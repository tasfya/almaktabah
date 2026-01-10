# frozen_string_literal: true

module TypesenseSearch
  # Merges facet counts from multiple Typesense search results.
  #
  # Multi-search returns separate results per collection. This class aggregates
  # facet counts across all results, with special handling for disjunctive faceting.
  #
  # == Disjunctive Faceting
  # When a scholar filter is active, we want to show:
  # - Accurate counts for the SELECTED scholar (from main queries with filter)
  # - Counts for OTHER scholars (from extra queries without filter) for disjunctive UI
  #
  # Response structure example (with scholars filter):
  #   results[0..5] = main queries for each collection (with scholar filter)
  #   results[6..N] = extra queries for selected collections (without scholar filter)
  class FacetMerger
    # @param response [Hash] Typesense multi_search response
    # @param selected_indices [Set<Integer>] indices of collections user selected (for content_type filter)
    # @param scholars_filtered [Boolean] true if scholar filter is active
    # @param content_types_filtered [Boolean] true if content_type filter is active
    # @param selected_scholars [Array<String>] names of selected scholars (for accurate counts)
    def initialize(response, selected_indices:, scholars_filtered: false, content_types_filtered: false, selected_scholars: [])
      @response = response
      @selected_indices = selected_indices
      @scholars_filtered = scholars_filtered
      @content_types_filtered = content_types_filtered
      @selected_scholars = Set.new(selected_scholars)
    end

    # @return [Hash] facets by field name, e.g. { "scholar_name" => [{ value: "X", count: 5 }, ...] }
    def merge
      merged = Hash.new { |h, k| h[k] = Hash.new(0) }
      main_results_count = Collections::NAMES.size

      @response["results"]&.each_with_index do |result, index|
        is_extra_scholar_query = index >= main_results_count
        is_selected = @selected_indices.include?(index)

        result["facet_counts"]&.each do |facet|
          field = facet["field_name"]

          facet["counts"]&.each do |count|
            scholar_name = count["value"]
            next unless include_facet?(field, is_extra_scholar_query, is_selected, scholar_name)

            merged[field][scholar_name] += count["count"]
          end
        end
      end

      merged.transform_values do |counts|
        counts.map { |value, count| { value: value, count: count } }
              .sort_by { |f| -f[:count] }
      end
    end

    private

    # Determines which facet values to include based on filter state.
    def include_facet?(field, is_extra_scholar_query, is_selected, scholar_name)
      return true unless field == "scholar_name"

      if @scholars_filtered
        # For SELECTED scholars: use main queries (accurate counts from filtered search)
        # For OTHER scholars: use extra queries (disjunctive counts from unfiltered search)
        if @selected_scholars.include?(scholar_name)
          !is_extra_scholar_query && is_selected
        else
          is_extra_scholar_query
        end
      elsif @content_types_filtered
        is_selected
      else
        true
      end
    end
  end
end
