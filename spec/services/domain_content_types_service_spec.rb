# frozen_string_literal: true

require "rails_helper"

RSpec.describe DomainContentTypesService do
  let(:domain) { create(:domain) }

  describe ".for_domain" do
    context "when domain_id is nil" do
      it "returns empty array without querying Typesense" do
        expect(Typesense::Client).not_to receive(:new)
        expect(described_class.for_domain(nil)).to eq([])
      end
    end

    context "when domain_id is blank" do
      it "returns empty array" do
        expect(described_class.for_domain("")).to eq([])
      end
    end

    context "when domain_id is present" do
      let(:typesense_response) do
        {
          "results" => [
            { "facet_counts" => [ { "field_name" => "content_type", "counts" => [ { "value" => "news", "count" => 10 } ] } ] },
            { "facet_counts" => [ { "field_name" => "content_type", "counts" => [ { "value" => "fatwa", "count" => 500 } ] } ] },
            { "facet_counts" => [ { "field_name" => "content_type", "counts" => [ { "value" => "lecture", "count" => 100 } ] } ] },
            { "facet_counts" => [ { "field_name" => "content_type", "counts" => [] } ] },
            { "facet_counts" => [ { "field_name" => "content_type", "counts" => [ { "value" => "article", "count" => 0 } ] } ] },
            { "facet_counts" => [ { "field_name" => "content_type", "counts" => [ { "value" => "book", "count" => 50 } ] } ] }
          ]
        }
      end

      before do
        allow_any_instance_of(Typesense::Client).to receive(:multi_search)
          .and_return(double(perform: typesense_response))
        Rails.cache.clear
      end

      it "returns content types sorted by count descending" do
        result = described_class.for_domain(domain.id)

        expect(result.map { |ct| ct[:type] }).to eq(%w[fatwa lecture book news])
      end

      it "excludes content types with zero count" do
        result = described_class.for_domain(domain.id)

        expect(result.map { |ct| ct[:type] }).not_to include("article")
      end

      it "returns correct counts" do
        result = described_class.for_domain(domain.id)

        expect(result.find { |ct| ct[:type] == "fatwa" }[:count]).to eq(500)
        expect(result.find { |ct| ct[:type] == "lecture" }[:count]).to eq(100)
      end

      it "uses correct cache key format" do
        expect(described_class.cache_key(domain.id)).to eq("domain_content_types/#{domain.id}")
      end
    end

    context "when Typesense errors" do
      before do
        allow_any_instance_of(Typesense::Client).to receive(:multi_search)
          .and_raise(Typesense::Error.new("Connection failed"))
        Rails.cache.clear
      end

      it "returns empty array" do
        expect(described_class.for_domain(domain.id)).to eq([])
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/DomainContentTypesService error/)
        described_class.for_domain(domain.id)
      end
    end
  end

  describe ".invalidate_cache" do
    it "removes the cached result for the domain" do
      cache_key = "domain_content_types/#{domain.id}"
      Rails.cache.write(cache_key, [ { type: "book", count: 10 } ])

      described_class.invalidate_cache(domain.id)

      expect(Rails.cache.read(cache_key)).to be_nil
    end
  end

  describe "cache invalidation via DomainAssignment" do
    let(:book) { create(:book, :without_domain) }

    it "calls invalidate_cache when content is assigned to domain" do
      expect(described_class).to receive(:invalidate_cache).with(domain.id)
      book.assign_to(domain)
    end

    it "calls invalidate_cache when content is unassigned from domain" do
      book.assign_to(domain)

      expect(described_class).to receive(:invalidate_cache).with(domain.id)
      book.unassign_from(domain)
    end
  end
end
