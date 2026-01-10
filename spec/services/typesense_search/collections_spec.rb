# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypesenseSearch::Collections do
  describe "NAMES" do
    it "contains all content collection names" do
      expect(described_class::NAMES).to eq(%w[News Fatwa Lecture Series Article Book])
    end
  end

  describe "KEYS" do
    it "maps collection names to plural symbol keys" do
      expect(described_class::KEYS["Book"]).to eq(:books)
      expect(described_class::KEYS["Lecture"]).to eq(:lectures)
      expect(described_class::KEYS["Series"]).to eq(:series)
      expect(described_class::KEYS["Fatwa"]).to eq(:fatwas)
      expect(described_class::KEYS["News"]).to eq(:news)
      expect(described_class::KEYS["Article"]).to eq(:articles)
    end
  end

  describe "SEARCHABLE_FIELDS" do
    it "defines searchable fields for each collection" do
      expect(described_class::SEARCHABLE_FIELDS["Book"]).to eq("title,description,content_text,scholar_name")
      expect(described_class::SEARCHABLE_FIELDS["Fatwa"]).to eq("title,content_text,scholar_name")
      expect(described_class::SEARCHABLE_FIELDS["Article"]).to eq("title,content_text,scholar_name")
    end
  end

  describe "FACET_FIELDS" do
    it "defines common facet fields" do
      expect(described_class::FACET_FIELDS).to eq("content_type,scholar_name,media_type")
    end
  end

  describe ".key_for" do
    it "returns symbol key for collection name" do
      expect(described_class.key_for("Book")).to eq(:books)
      expect(described_class.key_for("News")).to eq(:news)
    end

    it "returns nil for unknown collection" do
      expect(described_class.key_for("Unknown")).to be_nil
    end
  end

  describe ".name_for_type" do
    it "capitalizes content type" do
      expect(described_class.name_for_type("book")).to eq("Book")
      expect(described_class.name_for_type(:lecture)).to eq("Lecture")
    end
  end

  describe ".index_for" do
    it "returns index of collection in NAMES array" do
      expect(described_class.index_for("News")).to eq(0)
      expect(described_class.index_for("Book")).to eq(5)
    end

    it "returns nil for unknown collection" do
      expect(described_class.index_for("Unknown")).to be_nil
    end
  end
end
