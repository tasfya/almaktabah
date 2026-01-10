# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypesenseSearch::FacetMerger do
  let(:collections_count) { TypesenseSearch::Collections::NAMES.size }

  def build_result(facet_counts: [], found: 0)
    { "found" => found, "hits" => [], "facet_counts" => facet_counts }
  end

  def build_facet(field, counts_hash)
    { "field_name" => field, "counts" => counts_hash.map { |v, c| { "value" => v, "count" => c } } }
  end

  describe "#merge" do
    context "with empty results" do
      let(:response) do
        { "results" => Array.new(collections_count) { build_result } }
      end

      it "returns empty hash" do
        merger = described_class.new(response, selected_indices: Set.new(0...collections_count))

        expect(merger.merge).to eq({})
      end
    end

    context "with single collection results" do
      let(:response) do
        results = Array.new(collections_count) { build_result }
        results[0] = build_result(facet_counts: [
          build_facet("content_type", { "news" => 5 }),
          build_facet("scholar_name", { "Scholar A" => 3 })
        ])
        { "results" => results }
      end

      it "extracts facets from results" do
        merger = described_class.new(response, selected_indices: Set.new([ 0 ]))
        result = merger.merge

        expect(result["content_type"]).to eq([ { value: "news", count: 5 } ])
        expect(result["scholar_name"]).to eq([ { value: "Scholar A", count: 3 } ])
      end
    end

    context "with multiple collections" do
      let(:response) do
        results = Array.new(collections_count) { build_result }
        results[0] = build_result(facet_counts: [
          build_facet("content_type", { "news" => 5 }),
          build_facet("scholar_name", { "Scholar A" => 3, "Scholar B" => 2 })
        ])
        results[5] = build_result(facet_counts: [
          build_facet("content_type", { "book" => 10 }),
          build_facet("scholar_name", { "Scholar A" => 7, "Scholar C" => 1 })
        ])
        { "results" => results }
      end

      it "merges facet counts across collections" do
        merger = described_class.new(response, selected_indices: Set.new([ 0, 5 ]))
        result = merger.merge

        expect(result["content_type"]).to contain_exactly(
          { value: "book", count: 10 },
          { value: "news", count: 5 }
        )
        expect(result["scholar_name"]).to contain_exactly(
          { value: "Scholar A", count: 10 },
          { value: "Scholar B", count: 2 },
          { value: "Scholar C", count: 1 }
        )
      end

      it "sorts facets by count descending" do
        merger = described_class.new(response, selected_indices: Set.new([ 0, 5 ]))
        result = merger.merge

        expect(result["scholar_name"].map { |f| f[:value] }).to eq([ "Scholar A", "Scholar B", "Scholar C" ])
      end
    end

    context "with scholars_filtered: true (disjunctive faceting)" do
      let(:response) do
        results = Array.new(collections_count) { build_result }
        # Main query result (with scholar filter applied)
        results[0] = build_result(facet_counts: [
          build_facet("content_type", { "news" => 2 }),
          build_facet("scholar_name", { "Scholar A" => 2 }) # filtered count
        ])
        # Extra disjunctive query (without scholar filter)
        results << build_result(facet_counts: [
          build_facet("scholar_name", { "Scholar A" => 5, "Scholar B" => 3 }) # unfiltered counts
        ])
        { "results" => results }
      end

      it "uses scholar counts from extra disjunctive queries only" do
        merger = described_class.new(
          response,
          selected_indices: Set.new([ 0 ]),
          scholars_filtered: true
        )
        result = merger.merge

        # Scholar counts should come from extra query (index >= collections_count)
        expect(result["scholar_name"]).to contain_exactly(
          { value: "Scholar A", count: 5 },
          { value: "Scholar B", count: 3 }
        )
      end

      it "uses content_type from main queries" do
        merger = described_class.new(
          response,
          selected_indices: Set.new([ 0 ]),
          scholars_filtered: true
        )
        result = merger.merge

        expect(result["content_type"]).to eq([ { value: "news", count: 2 } ])
      end
    end

    context "with content_types_filtered: true" do
      let(:response) do
        results = Array.new(collections_count) { build_result }
        # Selected collection
        results[0] = build_result(facet_counts: [
          build_facet("scholar_name", { "Scholar A" => 5 })
        ])
        # Unselected collection
        results[5] = build_result(facet_counts: [
          build_facet("scholar_name", { "Scholar B" => 10 })
        ])
        { "results" => results }
      end

      it "uses scholar counts only from selected collections" do
        merger = described_class.new(
          response,
          selected_indices: Set.new([ 0 ]), # Only News selected
          content_types_filtered: true
        )
        result = merger.merge

        # Should only have Scholar A from selected collection
        expect(result["scholar_name"]).to eq([ { value: "Scholar A", count: 5 } ])
      end
    end

    context "with no filters" do
      let(:response) do
        results = Array.new(collections_count) { build_result }
        results[0] = build_result(facet_counts: [
          build_facet("scholar_name", { "Scholar A" => 3 })
        ])
        results[5] = build_result(facet_counts: [
          build_facet("scholar_name", { "Scholar B" => 7 })
        ])
        { "results" => results }
      end

      it "includes all scholar facets" do
        merger = described_class.new(
          response,
          selected_indices: Set.new([ 0, 5 ])
        )
        result = merger.merge

        expect(result["scholar_name"]).to contain_exactly(
          { value: "Scholar A", count: 3 },
          { value: "Scholar B", count: 7 }
        )
      end
    end
  end
end
