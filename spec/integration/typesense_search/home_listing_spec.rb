# frozen_string_literal: true

require "rails_helper"

# Real-Typesense integration spec for the home listing screens, which query
# across all collections: HomeBrowseService (grouped browse) and
# MixedSearchService (union search).
RSpec.describe "Home listing search (real Typesense)", :typesense do
  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }

  describe TypesenseSearch::HomeBrowseService do
    it "groups newest records by collection for the home browse screen" do
      book = create(:book, title: "Home Book", scholar: scholar)
      lecture = create(:lecture, title: "Home Lecture", scholar: scholar)
      index_records(book, lecture)

      result = described_class.new(per_page: 6).call

      expect(result.grouped_hits[:books].map(&:title)).to eq([ "Home Book" ])
      expect(result.grouped_hits[:lectures].map(&:title)).to eq([ "Home Lecture" ])
      expect(result.total_found).to eq(2)
    end
  end

  describe TypesenseSearch::MixedSearchService do
    it "returns mixed hits across collections matching the query" do
      book = create(:book, title: "Tawhid Explained", scholar: scholar)
      lecture = create(:lecture, title: "Tawhid Lecture", scholar: scholar)
      unrelated = create(:book, title: "Unrelated Fiqh", scholar: scholar)
      index_records(book, lecture, unrelated)

      result = described_class.new(query: "Tawhid").call

      titles = result.grouped_hits[:mixed].map(&:title)
      expect(titles).to contain_exactly("Tawhid Explained", "Tawhid Lecture")
    end

    it "filters mixed results by content_type" do
      index_records(
        create(:book, title: "Tawhid Book", scholar: scholar),
        create(:lecture, title: "Tawhid Lecture", scholar: scholar)
      )

      result = described_class.new(query: "Tawhid", content_types: [ "book" ]).call

      titles = result.grouped_hits[:mixed].map(&:title)
      expect(titles).to eq([ "Tawhid Book" ])
    end
  end
end
