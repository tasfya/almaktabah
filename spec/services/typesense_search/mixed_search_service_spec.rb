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

    context "with both content_types and scholars filtered" do
      let(:facets_response_with_extra_queries) do
        # 6 main queries + 2 extra scholar queries for selected collections
        main_results = TypesenseSearch::Collections::NAMES.map.with_index do |collection, i|
          facets = []
          if collection == "News"
            facets = [
              { "field_name" => "content_type", "counts" => [ { "value" => "news", "count" => 1 } ] },
              { "field_name" => "scholar_name", "counts" => [ { "value" => "Scholar A", "count" => 1 } ] }
            ]
          elsif collection == "Lecture"
            facets = [
              { "field_name" => "content_type", "counts" => [ { "value" => "lecture", "count" => 3 } ] },
              { "field_name" => "scholar_name", "counts" => [ { "value" => "Scholar A", "count" => 3 } ] }
            ]
          end
          { "found" => 0, "hits" => [], "facet_counts" => facets }
        end
        # Extra disjunctive queries for News and Lecture (without scholar filter)
        extra_results = [
          { "found" => 0, "hits" => [], "facet_counts" => [
            { "field_name" => "scholar_name", "counts" => [
              { "value" => "Scholar A", "count" => 1 },
              { "value" => "Scholar B", "count" => 2 }
            ] }
          ] },
          { "found" => 0, "hits" => [], "facet_counts" => [
            { "field_name" => "scholar_name", "counts" => [
              { "value" => "Scholar A", "count" => 3 },
              { "value" => "Scholar B", "count" => 5 }
            ] }
          ] }
        ]
        { "results" => main_results + extra_results }
      end

      let(:union_response) do
        { "found" => 4, "hits" => [
          { "document" => { "id" => "1", "content_type" => "news" }, "highlights" => [] },
          { "document" => { "id" => "2", "content_type" => "lecture" }, "highlights" => [] },
          { "document" => { "id" => "3", "content_type" => "lecture" }, "highlights" => [] },
          { "document" => { "id" => "4", "content_type" => "lecture" }, "highlights" => [] }
        ] }
      end

      before do
        allow(mock_multi_search).to receive(:perform).and_return(union_response, facets_response_with_extra_queries)
      end

      it "sums scholar counts from extra disjunctive queries across selected content types" do
        result = described_class.new(
          query: "test",
          content_types: %w[news lecture],
          scholars: [ "Scholar A" ]
        ).call

        scholar_facets = result.facets["scholar_name"]
        # Scholar A: 1 (from News extra) + 3 (from Lecture extra) = 4
        # Scholar B: 2 (from News extra) + 5 (from Lecture extra) = 7
        expect(scholar_facets).to include(
          { value: "Scholar A", count: 4 },
          { value: "Scholar B", count: 7 }
        )
      end

      it "sends extra disjunctive queries for each selected collection" do
        described_class.new(
          query: "test",
          content_types: %w[news lecture],
          scholars: [ "Scholar A" ]
        ).call

        # Verify the facet searches include extra queries
        facet_call = mock_multi_search.as_null_object
        expect(mock_multi_search).to have_received(:perform).with(
          hash_including(:searches),
          hash_including("per_page" => 0)
        ) do |args, _|
          searches = args[:searches]
          # Should have 6 main + 2 extra = 8 searches
          expect(searches.size).to eq(8)
          # Last 2 should be extra scholar queries without scholar filter
          extra_queries = searches.last(2)
          extra_queries.each do |q|
            expect(q["facet_by"]).to eq("scholar_name")
            expect(q["filter_by"]).not_to include("scholar_name")
          end
        end
      end

      it "sums content_type counts from main queries" do
        result = described_class.new(
          query: "test",
          content_types: %w[news lecture],
          scholars: [ "Scholar A" ]
        ).call

        content_type_facets = result.facets["content_type"]
        expect(content_type_facets).to include(
          { value: "news", count: 1 },
          { value: "lecture", count: 3 }
        )
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
