require 'rails_helper'

RSpec.describe TypesenseSearchService::SearchResult do
  let(:empty_grouped_hits) do
    { books: [], lectures: [], lessons: [], series: [], fatwas: [], news: [], scholars: [] }
  end

  describe '#total_pages' do
    it 'calculates correct number of pages' do
      result = described_class.new(
        grouped_hits: empty_grouped_hits,
        facets: {},
        total_found: 25,
        page: 1,
        per_page: 10
      )

      expect(result.total_pages).to eq(3)
    end

    it 'rounds up partial pages' do
      result = described_class.new(
        grouped_hits: empty_grouped_hits,
        facets: {},
        total_found: 21,
        page: 1,
        per_page: 10
      )

      expect(result.total_pages).to eq(3)
    end

    it 'returns 0 when per_page is 0' do
      result = described_class.new(
        grouped_hits: empty_grouped_hits,
        facets: {},
        total_found: 10,
        page: 1,
        per_page: 0
      )

      expect(result.total_pages).to eq(0)
    end

    it 'returns 0 when no results' do
      result = described_class.new(
        grouped_hits: empty_grouped_hits,
        facets: {},
        total_found: 0,
        page: 1,
        per_page: 10
      )

      expect(result.total_pages).to eq(0)
    end
  end

  describe '#empty?' do
    it 'returns true when total_found is 0' do
      result = described_class.new(
        grouped_hits: empty_grouped_hits,
        facets: {},
        total_found: 0,
        page: 1,
        per_page: 10
      )

      expect(result.empty?).to be true
    end

    it 'returns false when total_found is positive' do
      result = described_class.new(
        grouped_hits: empty_grouped_hits,
        facets: {},
        total_found: 5,
        page: 1,
        per_page: 10
      )

      expect(result.empty?).to be false
    end
  end

  describe '#has_results_for?' do
    it 'returns true when type has results' do
      grouped_hits = empty_grouped_hits.merge(books: [ double("hit") ])
      result = described_class.new(
        grouped_hits: grouped_hits,
        facets: {},
        total_found: 1,
        page: 1,
        per_page: 10
      )

      expect(result.has_results_for?(:books)).to be true
      expect(result.has_results_for?("books")).to be true
    end

    it 'returns false when type has no results' do
      result = described_class.new(
        grouped_hits: empty_grouped_hits,
        facets: {},
        total_found: 0,
        page: 1,
        per_page: 10
      )

      expect(result.has_results_for?(:books)).to be false
    end
  end
end
