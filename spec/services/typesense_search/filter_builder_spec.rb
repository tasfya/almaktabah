# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypesenseSearch::FilterBuilder do
  describe "#build" do
    context "with no filters" do
      it "returns empty string" do
        builder = described_class.new

        expect(builder.build).to eq("")
      end
    end

    context "with domain_id" do
      it "builds domain filter" do
        builder = described_class.new(domain_id: 123)

        expect(builder.build).to eq("domain_ids:=[123]")
      end
    end

    context "with scholars" do
      it "builds scholar filter with single scholar" do
        builder = described_class.new(scholars: [ "Ibn Baz" ])

        expect(builder.build).to eq("scholar_name:=[`Ibn Baz`]")
      end

      it "builds scholar filter with multiple scholars" do
        builder = described_class.new(scholars: %w[Ibn\ Baz Al-Albani])

        expect(builder.build).to eq("scholar_name:=[`Ibn Baz`,`Al-Albani`]")
      end

      it "sanitizes backticks in scholar names" do
        builder = described_class.new(scholars: [ "Scholar`Name" ])

        expect(builder.build).to eq("scholar_name:=[`ScholarName`]")
      end

      it "ignores blank scholars" do
        builder = described_class.new(scholars: [ "Ibn Baz", "", nil ])

        expect(builder.build).to eq("scholar_name:=[`Ibn Baz`]")
      end
    end

    context "with domain_id and scholars" do
      it "combines filters with &&" do
        builder = described_class.new(domain_id: 123, scholars: [ "Ibn Baz" ])

        expect(builder.build).to eq("domain_ids:=[123] && scholar_name:=[`Ibn Baz`]")
      end
    end
  end

  describe "#without_scholars" do
    context "with no filters" do
      it "returns empty string" do
        builder = described_class.new

        expect(builder.without_scholars).to eq("")
      end
    end

    context "with domain_id only" do
      it "returns domain filter" do
        builder = described_class.new(domain_id: 123)

        expect(builder.without_scholars).to eq("domain_ids:=[123]")
      end
    end

    context "with scholars only" do
      it "returns empty string (excludes scholars)" do
        builder = described_class.new(scholars: [ "Ibn Baz" ])

        expect(builder.without_scholars).to eq("")
      end
    end

    context "with content_types" do
      it "builds content_type filter" do
        builder = described_class.new(content_types: %w[book lecture])

        expect(builder.without_scholars).to eq("content_type:=[`book`,`lecture`]")
      end

      it "normalizes content types to lowercase" do
        builder = described_class.new(content_types: %w[Book LECTURE])

        expect(builder.without_scholars).to eq("content_type:=[`book`,`lecture`]")
      end
    end

    context "with domain_id and content_types" do
      it "combines filters with &&" do
        builder = described_class.new(domain_id: 123, content_types: [ "book" ])

        expect(builder.without_scholars).to eq("domain_ids:=[123] && content_type:=[`book`]")
      end
    end
  end

  describe "#content_types_filter (via without_scholars)" do
    it "returns nil when no content types" do
      builder = described_class.new

      expect(builder.without_scholars).to eq("")
    end

    it "builds content type filter" do
      builder = described_class.new(content_types: %w[book article])

      expect(builder.without_scholars).to eq("content_type:=[`book`,`article`]")
    end

    it "sanitizes backticks in content types" do
      builder = described_class.new(content_types: [ "book`test" ])

      expect(builder.without_scholars).to eq("content_type:=[`booktest`]")
    end
  end
end
