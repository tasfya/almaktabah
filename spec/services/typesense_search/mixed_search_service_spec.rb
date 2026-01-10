# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypesenseSearch::MixedSearchService, type: :service do
  let(:mock_multi_search) { instance_double(Typesense::MultiSearch) }

  let(:empty_union_response) do
    { "found" => 0, "hits" => [] }
  end

  let(:empty_facets_response) do
    {
      "results" => TypesenseSearch::Collections::NAMES.map do |collection|
        {
          "request_params" => { "collection" => collection },
          "found" => 0,
          "hits" => [],
          "facet_counts" => []
        }
      end
    }
  end

  before do
    allow(TypesenseSearch::Client).to receive(:multi_search).and_return(mock_multi_search)
  end

  describe "#call" do
    context "with empty results" do
      before do
        allow(mock_multi_search).to receive(:perform).and_return(empty_union_response, empty_facets_response)
      end

      it "returns mixed results structure" do
        result = described_class.new(query: "test").call

        expect(result).to be_a(TypesenseSearch::SearchResult)
        expect(result.grouped_hits).to have_key(:mixed)
      end

      it "performs two API calls" do
        described_class.new(query: "test").call

        expect(mock_multi_search).to have_received(:perform).twice
      end
    end

    context "with results" do
      let(:union_response_with_hits) do
        {
          "found" => 2,
          "hits" => [
            { "document" => { "id" => "1", "title" => "Test Book", "content_type" => "book" }, "highlights" => [] },
            { "document" => { "id" => "2", "title" => "Test Article", "content_type" => "article" }, "highlights" => [] }
          ]
        }
      end

      before do
        allow(mock_multi_search).to receive(:perform).and_return(union_response_with_hits, empty_facets_response)
      end

      it "returns mixed hits sorted by relevance" do
        result = described_class.new(query: "test").call

        expect(result.grouped_hits[:mixed].size).to eq(2)
        expect(result.grouped_hits[:mixed].map(&:content_type)).to eq(%w[book article])
      end

      it "calculates total_found from union response" do
        result = described_class.new(query: "test").call

        expect(result.total_found).to eq(2)
      end
    end

    context "with pagination" do
      before do
        allow(mock_multi_search).to receive(:perform).and_return(empty_union_response, empty_facets_response)
      end

      it "passes page and per_page to common params" do
        described_class.new(query: "test", page: 3, per_page: 10).call

        expect(mock_multi_search).to have_received(:perform).with(
          hash_including(union: true),
          hash_including("page" => 3, "per_page" => 10)
        )
      end

      it "clamps per_page to MAX_PER_PAGE" do
        result = described_class.new(query: "test", per_page: 1000).call

        expect(result.per_page).to eq(TypesenseSearch::Collections::MAX_PER_PAGE)
      end

      it "clamps per_page to minimum of 1" do
        result = described_class.new(query: "test", per_page: 0).call

        expect(result.per_page).to eq(1)
      end

      it "clamps negative per_page to minimum of 1" do
        result = described_class.new(query: "test", per_page: -5).call

        expect(result.per_page).to eq(1)
      end
    end

    context "when Typesense returns an error" do
      before do
        allow(mock_multi_search).to receive(:perform).and_raise(::Typesense::Error::RequestMalformed.new("test error"))
      end

      it "returns empty result and logs error" do
        expect(Rails.logger).to receive(:error).with(/Typesense search error/)

        result = described_class.new(query: "test").call

        expect(result.empty?).to be true
        expect(result.grouped_hits[:mixed]).to eq([])
      end
    end
  end
end
