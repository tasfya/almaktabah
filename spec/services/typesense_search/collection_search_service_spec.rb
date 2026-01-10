# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypesenseSearch::CollectionSearchService, type: :service do
  let(:mock_multi_search) { instance_double(Typesense::MultiSearch) }

  let(:empty_response) do
    {
      "results" => [
        {
          "request_params" => { "collection" => "Book" },
          "found" => 0,
          "hits" => [],
          "facet_counts" => []
        }
      ]
    }
  end

  before do
    allow(TypesenseSearch::Client).to receive(:multi_search).and_return(mock_multi_search)
  end

  describe "#call" do
    context "with browse mode (no query)" do
      before do
        allow(mock_multi_search).to receive(:perform).and_return(empty_response)
      end

      it "performs wildcard search" do
        described_class.new(collection: "book").call

        expect(mock_multi_search).to have_received(:perform).with(
          anything,
          hash_including("q" => "*", "sort_by" => "created_at_ts:desc")
        )
      end

      it "returns single collection results" do
        result = described_class.new(collection: "book").call

        expect(result.grouped_hits.keys).to eq([ :books ])
      end
    end

    context "with search mode (with query)" do
      before do
        allow(mock_multi_search).to receive(:perform).and_return(empty_response)
      end

      it "performs text search" do
        described_class.new(collection: "book", query: "test").call

        expect(mock_multi_search).to have_received(:perform).with(
          anything,
          hash_including("q" => "test", "sort_by" => "_text_match:desc")
        )
      end
    end

    context "with results" do
      let(:response_with_hits) do
        {
          "results" => [
            {
              "request_params" => { "collection" => "Book" },
              "found" => 2,
              "hits" => [
                { "document" => { "id" => "1", "title" => "Test Book", "content_type" => "book" }, "highlights" => [] },
                { "document" => { "id" => "2", "title" => "Another Book", "content_type" => "book" }, "highlights" => [] }
              ],
              "facet_counts" => [
                { "field_name" => "scholar_name", "counts" => [ { "value" => "Scholar A", "count" => 2 } ] }
              ]
            }
          ]
        }
      end

      before do
        allow(mock_multi_search).to receive(:perform).and_return(response_with_hits)
      end

      it "returns SearchHit objects" do
        result = described_class.new(collection: "book").call

        expect(result.grouped_hits[:books].first).to be_a(TypesenseSearch::SearchHit)
        expect(result.grouped_hits[:books].first.title).to eq("Test Book")
      end

      it "calculates total_found" do
        result = described_class.new(collection: "book").call

        expect(result.total_found).to eq(2)
      end

      it "extracts facets" do
        result = described_class.new(collection: "book").call

        expect(result.facets["scholar_name"]).to be_present
        expect(result.facets["scholar_name"].first[:value]).to eq("Scholar A")
      end
    end

    context "with pagination" do
      before do
        allow(mock_multi_search).to receive(:perform).and_return(empty_response)
      end

      it "stores page and per_page in result" do
        result = described_class.new(collection: "book", page: 2, per_page: 10).call

        expect(result.page).to eq(2)
        expect(result.per_page).to eq(10)
      end

      it "clamps per_page to MAX_PER_PAGE" do
        result = described_class.new(collection: "book", per_page: 1000).call

        expect(result.per_page).to eq(TypesenseSearch::Collections::MAX_PER_PAGE)
      end

      it "clamps per_page to minimum of 1" do
        result = described_class.new(collection: "book", per_page: 0).call

        expect(result.per_page).to eq(1)
      end

      it "clamps negative per_page to minimum of 1" do
        result = described_class.new(collection: "book", per_page: -5).call

        expect(result.per_page).to eq(1)
      end
    end

    context "when Typesense returns an error" do
      before do
        allow(mock_multi_search).to receive(:perform).and_raise(::Typesense::Error::RequestMalformed.new("test error"))
      end

      it "returns empty result and logs error" do
        expect(Rails.logger).to receive(:error).with(/Typesense collection search error/)

        result = described_class.new(collection: "book").call

        expect(result.empty?).to be true
        expect(result.grouped_hits[:books]).to eq([])
      end
    end

    context "with scholar filter" do
      let(:response_with_disjunctive_facets) do
        {
          "results" => [
            {
              "request_params" => { "collection" => "Book" },
              "found" => 1,
              "hits" => [
                { "document" => { "id" => "1", "title" => "Test Book", "content_type" => "book" }, "highlights" => [] }
              ],
              "facet_counts" => [
                { "field_name" => "scholar_name", "counts" => [ { "value" => "Scholar A", "count" => 1 } ] }
              ]
            },
            {
              "request_params" => { "collection" => "Book" },
              "found" => 0,
              "hits" => [],
              "facet_counts" => [
                { "field_name" => "scholar_name", "counts" => [
                  { "value" => "Scholar A", "count" => 1 },
                  { "value" => "Scholar B", "count" => 3 },
                  { "value" => "Scholar C", "count" => 2 }
                ] }
              ]
            }
          ]
        }
      end

      before do
        allow(mock_multi_search).to receive(:perform).and_return(response_with_disjunctive_facets)
      end

      it "returns scholar facets from disjunctive query" do
        result = described_class.new(collection: "book", scholars: [ "Scholar A" ]).call

        expect(result.facets["scholar_name"]).to be_present
        expect(result.facets["scholar_name"].map { |f| f[:value] }).to eq([ "Scholar B", "Scholar C", "Scholar A" ])
      end

      it "sends two queries (main + disjunctive scholar)" do
        described_class.new(collection: "book", scholars: [ "Scholar A" ]).call

        expect(mock_multi_search).to have_received(:perform).with(
          hash_including(searches: array_including(
            hash_including("collection" => "Book", "facet_by" => TypesenseSearch::Collections::FACET_FIELDS),
            hash_including("collection" => "Book", "facet_by" => "scholar_name", "per_page" => 0)
          )),
          anything
        )
      end
    end
  end
end
