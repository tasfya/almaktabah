# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypesenseSearch::HomeBrowseService, type: :service do
  let(:mock_multi_search) { instance_double(Typesense::MultiSearch) }

  let(:empty_response) do
    {
      "results" => TypesenseSearch::Collections::NAMES.map do |collection|
        {
          "request_params" => { "collection" => "#{collection}_test" },
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
        allow(mock_multi_search).to receive(:perform).and_return(empty_response)
      end

      it "returns grouped results for all collections" do
        result = described_class.new.call

        expect(result).to be_a(TypesenseSearch::SearchResult)
        expect(result.grouped_hits.keys).to match_array(TypesenseSearch::Collections::KEYS.values)
      end

      it "performs wildcard search" do
        described_class.new.call

        expect(mock_multi_search).to have_received(:perform).with(
          hash_including(searches: array_including(hash_including("collection" => "Book"))),
          hash_including("q" => "*", "sort_by" => "created_at_ts:desc")
        )
      end
    end

    context "with results" do
      let(:response_with_hits) do
        results = TypesenseSearch::Collections::NAMES.map.with_index do |collection, i|
          {
            "request_params" => { "collection" => collection },
            "found" => i == 5 ? 2 : 0, # Book collection has hits
            "hits" => i == 5 ? [
              { "document" => { "id" => "1", "title" => "Test Book", "content_type" => "book" }, "highlights" => [] }
            ] : [],
            "facet_counts" => []
          }
        end
        { "results" => results }
      end

      before do
        allow(mock_multi_search).to receive(:perform).and_return(response_with_hits)
      end

      it "returns SearchHit objects" do
        result = described_class.new.call

        expect(result.grouped_hits[:books].first).to be_a(TypesenseSearch::SearchHit)
        expect(result.grouped_hits[:books].first.title).to eq("Test Book")
      end

      it "calculates total_found" do
        result = described_class.new.call

        expect(result.total_found).to eq(2)
      end
    end

    context "with domain_id filter" do
      before do
        allow(mock_multi_search).to receive(:perform).and_return(empty_response)
      end

      it "applies domain filter" do
        described_class.new(domain_id: 123).call

        expect(mock_multi_search).to have_received(:perform).with(
          hash_including(searches: array_including(hash_including("filter_by" => "domain_ids:=[123]"))),
          anything
        )
      end
    end

    context "when Typesense returns an error" do
      before do
        allow(mock_multi_search).to receive(:perform).and_raise(::Typesense::Error::RequestMalformed.new("test error"))
      end

      it "returns empty result and logs error" do
        expect(Rails.logger).to receive(:error).with(/Typesense browse error/)

        result = described_class.new.call

        expect(result.empty?).to be true
        expect(result.total_found).to eq(0)
      end
    end
  end
end
