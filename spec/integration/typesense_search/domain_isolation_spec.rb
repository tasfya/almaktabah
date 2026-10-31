# frozen_string_literal: true

require "rails_helper"

# Every tenant shares the same Typesense collections, separated only by the
# `domain_ids` filter. A record assigned to another domain (or to none) must
# never show up in this domain's hits, facet counts or content-type menu.
RSpec.describe "Typesense domain isolation", :typesense do
  let(:domain) { create(:domain, host: "mine.example.com") }
  let(:other_domain) { create(:domain, host: "theirs.example.com") }
  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }
  let(:other_scholar) { create(:scholar, full_name: "Muhammad Salih") }

  def on(target_domain, record)
    record.update!(domains: Array(target_domain))
    index_records(record)
    record
  end

  def facet_counts(result, field)
    Array(result.facets[field]).to_h { |f| [ f[:value], f[:count] ] }
  end

  describe DomainContentTypesService do
    it "lists only the content types indexed on the domain, with their counts" do
      on(domain, create(:book, title: "Mine 1", scholar: scholar))
      on(domain, create(:book, title: "Mine 2", scholar: scholar))
      on(domain, create(:fatwa, title: "Mine Fatwa", scholar: scholar))
      on(other_domain, create(:lecture, title: "Their Lecture", scholar: scholar))
      on([], create(:article, title: "Nowhere Article", scholar: scholar))

      expect(described_class.for_domain(domain.id)).to eq([
        { type: "book", count: 2 },
        { type: "fatwa", count: 1 }
      ])
      expect(described_class.for_domain(other_domain.id)).to eq([ { type: "lecture", count: 1 } ])
    end

    it "returns no types for a domain with nothing indexed" do
      on(other_domain, create(:book, title: "Their Book", scholar: scholar))

      expect(described_class.for_domain(domain.id)).to eq([])
    end

    it "does not count unpublished records" do
      on(domain, create(:news, title: "Draft News", scholar: scholar, published: false))

      expect(described_class.for_domain(domain.id)).to eq([])
    end
  end

  describe TypesenseSearch::HomeBrowseService do
    it "returns only this domain's hits and facets" do
      on(domain, create(:book, title: "Mine Book", scholar: scholar))
      on(other_domain, create(:book, title: "Their Book", scholar: other_scholar))
      on(other_domain, create(:lecture, title: "Their Lecture", scholar: other_scholar))

      result = described_class.new(domain_id: domain.id).call

      expect(result.grouped_hits.values.flatten.map(&:title)).to eq([ "Mine Book" ])
      expect(result.total_found).to eq(1)
      expect(facet_counts(result, "scholar_name")).to eq("Abdul Aziz" => 1)
      expect(facet_counts(result, "content_type")).to eq("book" => 1)
    end

    it "keeps the disjunctive scholar facet counts on this domain while a scholar filter is active" do
      on(domain, create(:book, title: "Mine Book", scholar: scholar))
      on(other_domain, create(:book, title: "Their Book", scholar: other_scholar))

      result = described_class.new(domain_id: domain.id, scholars: [ "Abdul Aziz" ]).call

      expect(result.grouped_hits[:books].map(&:title)).to eq([ "Mine Book" ])
      expect(facet_counts(result, "scholar_name")).to eq("Abdul Aziz" => 1)
    end
  end

  describe TypesenseSearch::MixedSearchService do
    it "returns only this domain's hits and facets" do
      on(domain, create(:book, title: "Tawhid Mine", scholar: scholar))
      on(other_domain, create(:article, title: "Tawhid Theirs", scholar: other_scholar))

      result = described_class.new(query: "Tawhid", domain_id: domain.id).call

      expect(result.grouped_hits[:mixed].map(&:title)).to eq([ "Tawhid Mine" ])
      expect(result.total_found).to eq(1)
      expect(facet_counts(result, "scholar_name")).to eq("Abdul Aziz" => 1)
      expect(facet_counts(result, "content_type")).to eq("book" => 1)
    end

    it "keeps the disjunctive scholar facet counts on this domain while a scholar filter is active" do
      on(domain, create(:book, title: "Tawhid Mine", scholar: scholar))
      on(other_domain, create(:book, title: "Tawhid Theirs", scholar: other_scholar))

      result = described_class.new(query: "Tawhid", domain_id: domain.id, scholars: [ "Abdul Aziz" ]).call

      expect(result.grouped_hits[:mixed].map(&:title)).to eq([ "Tawhid Mine" ])
      expect(facet_counts(result, "scholar_name")).to eq("Abdul Aziz" => 1)
    end
  end

  describe TypesenseSearch::CollectionSearchService do
    it "keeps the disjunctive scholar facet counts on this domain while a scholar filter is active" do
      on(domain, create(:book, title: "Mine Book", scholar: scholar))
      on(other_domain, create(:book, title: "Their Book", scholar: other_scholar))

      result = described_class.new(collection: "book", domain_id: domain.id, scholars: [ "Abdul Aziz" ]).call

      expect(result.grouped_hits[:books].map(&:title)).to eq([ "Mine Book" ])
      expect(facet_counts(result, "scholar_name")).to eq("Abdul Aziz" => 1)
    end

    it "does not return a record assigned to no domain" do
      on([], create(:book, title: "Orphan Book", scholar: scholar))

      result = described_class.new(collection: "book", domain_id: domain.id).call

      expect(result.total_found).to eq(0)
    end
  end
end
