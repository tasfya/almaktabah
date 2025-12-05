require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end
  let(:domain) { create(:domain, host: "localhost") }

  # Mock the TypesenseSearchService to avoid needing a running Typesense instance
  let(:mock_search_result) do
    TypesenseSearchService::SearchResult.new(
      grouped_hits: {
        books: [],
        lectures: [],
        lessons: [],
        series: [],
        fatwas: [],
        news: [],
        articles: []
      },
      facets: {},
      total_found: 0,
      page: 1,
      per_page: 5
    )
  end

  describe "GET #index" do
    let!(:book) { create(:book, title: "Test Book Title", description: "Test book description", published: true, published_at: DateTime.new) }
    let!(:lecture) { create(:lecture, :with_domain, title: "Test Lecture", description: "Test lecture description", published: true, published_at: DateTime.new) }
    let!(:lesson) { create(:lesson, title: "Test Lesson", description: "Test lesson description", published: true, published_at: DateTime.new) }
    let!(:series) { create(:series, title: "Test Series", description: "Test series description", published: true, published_at: DateTime.new) }
    let!(:news) { create(:news, title: "Test News", description: "Test news description", published: true, published_at: DateTime.new) }
    let!(:fatwa) { create(:fatwa, title: "Test Fatwa", published: true, published_at: DateTime.new) }
    let!(:scholar) { create(:scholar, first_name: "Test", last_name: "Scholar", published: true, published_at: DateTime.new) }

    before do
      allow_any_instance_of(TypesenseSearchService).to receive(:search).and_return(mock_search_result)
    end

    context "when no query is provided" do
      it "renders the search page with default results (browsing mode)" do
        result_with_data = TypesenseSearchService::SearchResult.new(
          grouped_hits: { books: [], lectures: [], lessons: [], series: [], fatwas: [], news: [], articles: [] },
          facets: {},
          total_found: 10,
          page: 1,
          per_page: 5
        )
        allow_any_instance_of(TypesenseSearchService).to receive(:search).and_return(result_with_data)

        get :index

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to be_nil
        expect(assigns(:results)).to be_a(Hash)
        expect(assigns(:total_results)).to eq(10)
      end
    end

    context "when query is short" do
      it "allows single character queries" do
        get :index, params: { q: "a" }

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to eq("a")
        expect(assigns(:results)).to be_a(Hash)
      end

      it "shows default results for empty query (browsing mode)" do
        get :index, params: { q: " " }

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to eq("")
        expect(assigns(:results)).to be_a(Hash)
      end
    end

    context "when valid query is provided" do
      # Helper to create mock SearchHit (no DB access - pure value object)
      def mock_hit(content_type, title: "Test", slug: "test-slug")
        hit = double("SearchHit")
        allow(hit).to receive(:content_type).and_return(content_type)
        allow(hit).to receive(:title).and_return(title)
        allow(hit).to receive(:label).and_return(title)
        allow(hit).to receive(:url).and_return("/#{slug}")
        allow(hit).to receive(:description).and_return("Test description")
        hit
      end

      it "searches across all models and returns results" do
        result_with_data = TypesenseSearchService::SearchResult.new(
          grouped_hits: {
            books: [ mock_hit("book") ],
            lectures: [ mock_hit("lecture") ],
            lessons: [ mock_hit("lesson") ],
            series: [ mock_hit("series") ],
            fatwas: [ mock_hit("fatwa") ],
            news: [ mock_hit("news") ],
            articles: [ mock_hit("article") ]
          },
          facets: { "content_type" => [ { value: "book", count: 1 } ] },
          total_found: 7,
          page: 1,
          per_page: 5
        )
        allow_any_instance_of(TypesenseSearchService).to receive(:search).and_return(result_with_data)

        get :index, params: { q: "Test" }

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to eq("Test")
        expect(assigns(:results)).to be_a(Hash)
        expect(assigns(:total_results)).to eq(7)

        # Check that all model types are present - results are SearchHit objects, not AR
        expect(assigns(:results)).to have_key(:books)
        expect(assigns(:results)).to have_key(:lectures)
        expect(assigns(:results)).to have_key(:lessons)
        expect(assigns(:results)).to have_key(:series)
        expect(assigns(:results)).to have_key(:news)
        expect(assigns(:results)).to have_key(:fatwas)
        expect(assigns(:results)).to have_key(:articles)
      end

      it "calls TypesenseSearchService with correct parameters" do
        expect(TypesenseSearchService).to receive(:new).with(
          hash_including(q: "Test", domain_id: anything)
        ).and_call_original

        get :index, params: { q: "Test" }
      end

      it "calculates total results from service response" do
        result_with_data = TypesenseSearchService::SearchResult.new(
          grouped_hits: { books: [ mock_hit("book") ], lectures: [], lessons: [], series: [], fatwas: [], news: [], articles: [] },
          facets: {},
          total_found: 42,
          page: 1,
          per_page: 5
        )
        allow_any_instance_of(TypesenseSearchService).to receive(:search).and_return(result_with_data)

        get :index, params: { q: "Test" }

        expect(assigns(:total_results)).to eq(42)
      end
    end

    context "when no results are found" do
      it "returns empty results for non-matching query" do
        get :index, params: { q: "NonExistentSearchTerm" }

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to eq("NonExistentSearchTerm")
        expect(assigns(:total_results)).to eq(0)

        assigns(:results).values.each do |results|
          expect(results).to be_empty
        end
      end
    end

    context "with special characters in query" do
      it "handles queries with spaces" do
        get :index, params: { q: "Test Book" }

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to eq("Test Book")
      end

      it "strips whitespace from query" do
        get :index, params: { q: "  Test  " }

        expect(assigns(:query)).to eq("Test")
      end
    end

    context "facets" do
      it "assigns facets from service response" do
        result_with_facets = TypesenseSearchService::SearchResult.new(
          grouped_hits: { books: [], lectures: [], lessons: [], series: [], fatwas: [], news: [], articles: [] },
          facets: { "content_type" => [ { value: "book", count: 5 }, { value: "lecture", count: 3 } ] },
          total_found: 8,
          page: 1,
          per_page: 5
        )
        allow_any_instance_of(TypesenseSearchService).to receive(:search).and_return(result_with_facets)

        get :index, params: { q: "Test" }

        expect(assigns(:facets)).to eq({ "content_type" => [ { value: "book", count: 5 }, { value: "lecture", count: 3 } ] })
      end
    end

    context "breadcrumbs" do
      it "sets up search breadcrumbs" do
        expect(controller).to receive(:breadcrumb_for).with(
          I18n.t("navigation.search"),
          search_path
        )

        get :index
      end
    end
  end
end
