require 'rails_helper'

RSpec.describe TypesenseSearchService, type: :service do
  let(:domain) { create(:domain) }

  describe '#initialize' do
    it 'initializes with default values' do
      service = described_class.new

      expect(service.instance_variable_get(:@query)).to eq('')
      expect(service.instance_variable_get(:@domain_id)).to be_nil
      expect(service.instance_variable_get(:@page)).to eq(1)
      expect(service.instance_variable_get(:@per_page)).to eq(5)
    end

    it 'strips and stores query' do
      service = described_class.new(q: '  test query  ')

      expect(service.instance_variable_get(:@query)).to eq('test query')
    end

    it 'stores domain_id' do
      service = described_class.new(domain_id: domain.id)

      expect(service.instance_variable_get(:@domain_id)).to eq(domain.id)
    end

    it 'ensures page is at least 1' do
      service = described_class.new(page: 0)

      expect(service.instance_variable_get(:@page)).to eq(1)
    end

    it 'caps per_page at MAX_PER_PAGE' do
      service = described_class.new(per_page: 100)

      expect(service.instance_variable_get(:@per_page)).to eq(50)
    end
  end

  describe '#search' do
    let(:mock_client) { instance_double(Typesense::Client) }
    let(:mock_multi_search) { instance_double(Typesense::MultiSearch) }

    let(:empty_typesense_response) do
      {
        "results" => TypesenseSearchService::CONTENT_COLLECTIONS.map do |collection|
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
      allow(Typesense::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:multi_search).and_return(mock_multi_search)
    end

    context 'with empty query (browsing mode)' do
      before do
        allow(mock_multi_search).to receive(:perform).and_return(empty_typesense_response)
      end

      it 'performs wildcard search' do
        service = described_class.new(q: '')
        result = service.search

        expect(result).to be_a(TypesenseSearchService::SearchResult)
        expect(mock_multi_search).to have_received(:perform)
      end
    end

    context 'with short query' do
      before do
        allow(mock_multi_search).to receive(:perform).and_return(empty_typesense_response)
      end

      it 'still performs search for single character' do
        service = described_class.new(q: 'a')
        service.search

        expect(mock_multi_search).to have_received(:perform)
      end
    end

    context 'with valid query' do
      # Results order must match CONTENT_COLLECTIONS: News, Fatwa, Lecture, Lesson, Series, Article, Book
      let(:typesense_response) do
        {
          "results" => [
            {
              "request_params" => { "collection" => "News_test" },
              "found" => 0,
              "hits" => [],
              "facet_counts" => []
            },
            {
              "request_params" => { "collection" => "Fatwa_test" },
              "found" => 0,
              "hits" => [],
              "facet_counts" => []
            },
            {
              "request_params" => { "collection" => "Lecture_test" },
              "found" => 0,
              "hits" => [],
              "facet_counts" => []
            },
            {
              "request_params" => { "collection" => "Lesson_test" },
              "found" => 0,
              "hits" => [],
              "facet_counts" => []
            },
            {
              "request_params" => { "collection" => "Series_test" },
              "found" => 0,
              "hits" => [],
              "facet_counts" => []
            },
            {
              "request_params" => { "collection" => "Article_test" },
              "found" => 1,
              "hits" => [
                {
                  "document" => { "id" => "1", "title" => "Test Article", "content_type" => "article" },
                  "highlights" => [],
                  "text_match" => 80
                }
              ],
              "facet_counts" => [
                { "field_name" => "content_type", "counts" => [ { "value" => "article", "count" => 1 } ] }
              ]
            },
            {
              "request_params" => { "collection" => "Book_test" },
              "found" => 2,
              "hits" => [
                {
                  "document" => { "id" => "1", "title" => "Test Book", "content_type" => "book" },
                  "highlights" => [ { "field" => "title", "snippet" => "<mark>Test</mark> Book" } ],
                  "text_match" => 100
                },
                {
                  "document" => { "id" => "2", "title" => "Another Test", "content_type" => "book" },
                  "highlights" => [],
                  "text_match" => 90
                }
              ],
              "facet_counts" => [
                { "field_name" => "content_type", "counts" => [ { "value" => "book", "count" => 2 } ] }
              ]
            }
          ]
        }
      end

      before do
        allow(mock_multi_search).to receive(:perform).and_return(typesense_response)
      end

      it 'returns SearchResult with grouped hits' do
        service = described_class.new(q: 'test')
        result = service.search

        expect(result).to be_a(TypesenseSearchService::SearchResult)
        expect(result.grouped_hits).to have_key(:books)
        expect(result.grouped_hits).to have_key(:lectures)
        expect(result.grouped_hits).to have_key(:articles)
      end

      it 'calculates total_found from all collections' do
        service = described_class.new(q: 'test')
        result = service.search

        expect(result.total_found).to eq(3) # 2 books + 1 article
      end

      it 'merges facets from all collections' do
        service = described_class.new(q: 'test')
        result = service.search

        expect(result.facets).to have_key("content_type")
        # 2 books + 1 article = 3 total, but merged by value
        book_facet = result.facets["content_type"].find { |f| f[:value] == "book" }
        article_facet = result.facets["content_type"].find { |f| f[:value] == "article" }
        expect(book_facet[:count]).to eq(2)
        expect(article_facet[:count]).to eq(1)
      end

      it 'creates SearchHit objects for each hit' do
        service = described_class.new(q: 'test')
        result = service.search

        expect(result.grouped_hits[:books].first).to be_a(TypesenseSearchService::SearchHit)
        expect(result.grouped_hits[:books].first.title).to eq("Test Book")
      end

      it 'stores page and per_page in result' do
        service = described_class.new(q: 'test', page: 2, per_page: 10)
        result = service.search

        expect(result.page).to eq(2)
        expect(result.per_page).to eq(10)
      end
    end

    context 'when Typesense returns an error' do
      before do
        mock_client = instance_double(Typesense::Client)
        allow(Typesense::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:multi_search).and_raise(Typesense::Error::RequestMalformed.new("test error"))
      end

      it 'returns empty result and logs error' do
        service = described_class.new(q: 'test')

        expect(Rails.logger).to receive(:error).with(/Typesense search error/)

        result = service.search

        expect(result.empty?).to be true
        expect(result.total_found).to eq(0)
      end
    end
  end

  describe 'collection keys mapping' do
    it 'maps collection names to plural symbol keys' do
      expect(TypesenseSearchService::COLLECTION_KEYS["Book"]).to eq(:books)
      expect(TypesenseSearchService::COLLECTION_KEYS["Article"]).to eq(:articles)
    end
  end

  describe 'filter building' do
    context 'with domain_id' do
      it 'builds domain filter for content collections' do
        service = described_class.new(q: 'test', domain_id: 123)

        filter = service.send(:content_filter_string)
        expect(filter).to eq("domain_ids:=[123]")
      end
    end

    context 'without domain_id' do
      it 'returns empty filter string' do
        service = described_class.new(q: 'test')

        expect(service.send(:content_filter_string)).to eq("")
      end
    end
  end
end
