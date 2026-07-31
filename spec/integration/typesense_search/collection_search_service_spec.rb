# frozen_string_literal: true

require "rails_helper"

# Real-Typesense integration spec: indexes real records and exercises the
# CollectionSearchService query path (the per-type listing screens) against a
# running Typesense instance. See spec/support/typesense_integration.rb for gating.
RSpec.describe TypesenseSearch::CollectionSearchService, :typesense do
  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }

  describe "document <-> view contract" do
    it "returns an indexed published book with the fields the listing view reads" do
      book = create(:book, title: "Kitab al Tawhid", scholar: scholar)
      index_records(book)

      result = described_class.new(collection: "book", query: "Tawhid").call

      expect(result.total_found).to eq(1)
      hit = result.grouped_hits[:books].first
      expect(hit.title).to eq("Kitab al Tawhid")
      expect(hit.scholar_name).to eq("Abdul Aziz")
      expect(hit.content_type).to eq("book")
      expect(hit.slug).to be_present
      expect(hit.url).to be_present
    end
  end

  describe "publish gating" do
    it "does not return an unpublished record even when index! is called (guards false-green)" do
      published = create(:book, title: "Visible Book", scholar: scholar)
      unpublished = create(:book, title: "Hidden Book", scholar: scholar, published: false)
      index_records(published, unpublished)

      result = described_class.new(collection: "book").call

      expect(result.total_found).to eq(1)
      expect(result.grouped_hits[:books].map(&:title)).to eq([ "Visible Book" ])
    end
  end

  describe "browse mode (no query)" do
    it "returns records newest-first by created_at" do
      older = create(:book, title: "Older Book", scholar: scholar)
      newer = create(:book, title: "Newer Book", scholar: scholar)
      older.update_column(:created_at, 3.days.ago)
      newer.update_column(:created_at, 1.hour.ago)
      index_records(older, newer)

      result = described_class.new(collection: "book").call

      expect(result.grouped_hits[:books].map(&:title)).to eq([ "Newer Book", "Older Book" ])
    end
  end

  describe "scholar filtering" do
    it "returns only books whose scholar_name matches the filter" do
      other = create(:scholar, full_name: "Muhammad Salih")
      mine = create(:book, title: "Mine", scholar: scholar)
      theirs = create(:book, title: "Theirs", scholar: other)
      index_records(mine, theirs)

      result = described_class.new(collection: "book", scholars: [ "Abdul Aziz" ]).call

      expect(result.grouped_hits[:books].map(&:title)).to eq([ "Mine" ])
    end
  end

  describe "domain filtering" do
    it "returns only books assigned to the given domain" do
      d1 = create(:domain, host: "one.example.com")
      d2 = create(:domain, host: "two.example.com")
      in_d1 = create(:book, title: "In D1", scholar: scholar)
      in_d2 = create(:book, title: "In D2", scholar: scholar)
      in_d1.update!(domains: [ d1 ])
      in_d2.update!(domains: [ d2 ])
      index_records(in_d1, in_d2)

      result = described_class.new(collection: "book", domain_id: d1.id).call

      expect(result.grouped_hits[:books].map(&:title)).to eq([ "In D1" ])
    end
  end

  describe "facets" do
    it "returns scholar_name facet counts alongside the hits" do
      other = create(:scholar, full_name: "Muhammad Salih")
      index_records(
        create(:book, title: "A", scholar: scholar),
        create(:book, title: "B", scholar: scholar),
        create(:book, title: "C", scholar: other)
      )

      result = described_class.new(collection: "book").call

      counts = result.facets["scholar_name"].to_h { |f| [ f[:value], f[:count] ] }
      expect(counts).to eq("Abdul Aziz" => 2, "Muhammad Salih" => 1)
    end
  end

  describe "pagination" do
    it "honors per_page and reports total_pages" do
      index_records(*Array.new(3) { |i| create(:book, title: "Book #{i}", scholar: scholar) })

      result = described_class.new(collection: "book", per_page: 2, page: 1).call

      expect(result.total_found).to eq(3)
      expect(result.grouped_hits[:books].size).to eq(2)
      expect(result.total_pages).to eq(2)
    end
  end
end
