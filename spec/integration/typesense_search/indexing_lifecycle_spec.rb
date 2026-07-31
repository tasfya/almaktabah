# frozen_string_literal: true

require "rails_helper"

# Real-Typesense integration spec for the write/index path: verifies that the
# model `typesense` blocks produce documents the listing services can read, that
# the publish gate is honored, and that attribute blocks are nil-safe.
RSpec.describe "Typesense indexing lifecycle", :typesense do
  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }

  def search_books(query: nil)
    TypesenseSearch::CollectionSearchService.new(collection: "book", query: query).call
  end

  describe "add / remove" do
    it "makes a published record searchable, and remove_from_index! removes it" do
      book = create(:book, title: "Removable", scholar: scholar)
      index_records(book)
      expect(search_books.total_found).to eq(1)

      Book.remove_from_index!(book)
      expect(search_books.total_found).to eq(0)
    end
  end

  describe "conditional index (if: :published?)" do
    it "removes a record from the index when it becomes unpublished and is re-indexed" do
      book = create(:book, title: "Toggle", scholar: scholar)
      index_records(book)
      expect(search_books.total_found).to eq(1)

      book.update!(published: false)
      Book.index!(book)

      expect(search_books.total_found).to eq(0)
    end
  end

  describe "nil-safe attribute blocks" do
    it "indexes a book with a nil description without error" do
      book = create(:book, title: "No Description Book", description: nil, scholar: scholar)

      expect { index_records(book) }.not_to raise_error
      expect(search_books(query: "Description").total_found).to eq(1)
    end

    it "indexes an article with blank rich-text content without error" do
      article = create(:article, title: "Empty Article", scholar: scholar)

      expect { index_records(article) }.not_to raise_error
      result = TypesenseSearch::CollectionSearchService.new(collection: "article", query: "Empty").call
      expect(result.total_found).to eq(1)
    end
  end

  describe "every listing collection matches its model's index schema" do
    it "indexes and retrieves one record of each content type" do
      records = {
        "book" => create(:book, title: "Contract Book", scholar: scholar),
        "article" => create(:article, title: "Contract Article", scholar: scholar),
        "lecture" => create(:lecture, title: "Contract Lecture", scholar: scholar),
        "series" => create(:series, title: "Contract Series", scholar: scholar),
        "fatwa" => create(:fatwa, title: "Contract Fatwa", scholar: scholar),
        "news" => create(:news, title: "Contract News", scholar: scholar)
      }
      index_records(*records.values)

      records.each do |type, record|
        result = TypesenseSearch::CollectionSearchService.new(collection: type).call
        key = TypesenseSearch::Collections.key_for(type.capitalize)
        expect(result.total_found).to eq(1), "expected #{type} collection to contain exactly its record"
        expect(result.grouped_hits[key].first.title).to eq(record.title)
      end
    end
  end
end
