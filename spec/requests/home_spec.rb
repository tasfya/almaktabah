# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }

  before { host! "localhost" }

  def stub_search(service, result)
    instance_double(service, call: result).tap { |search| allow(service).to receive(:new).and_return(search) }
  end

  describe "GET /" do
    it "renders the search page" do
      stub_search(TypesenseSearch::HomeBrowseService, empty_search_result)
      get root_path
      expect(response).to have_http_status(:ok)
      expect(search_page_rendered?).to be(true)
    end

    it "browses six records per collection on the request's domain when there is no query" do
      stub_search(TypesenseSearch::HomeBrowseService, empty_search_result)
      allow(TypesenseSearch::MixedSearchService).to receive(:new)

      get root_path, params: { scholars: [ "Scholar A" ], content_types: [ "book" ] }

      expect(TypesenseSearch::HomeBrowseService).to have_received(:new).with(
        domain_id: domain.id, content_types: [ "book" ], scholars: [ "Scholar A" ], per_page: 6
      )
      expect(TypesenseSearch::MixedSearchService).not_to have_received(:new)
    end

    it "runs a mixed search on the request's domain when there is a query" do
      stub_search(TypesenseSearch::MixedSearchService, empty_mixed_search_result)
      allow(TypesenseSearch::HomeBrowseService).to receive(:new)

      get root_path, params: { q: "  tawhid  ", scholars: [ "Scholar A" ], content_types: [ "book" ], page: "2" }

      expect(TypesenseSearch::MixedSearchService).to have_received(:new).with(
        query: "tawhid", domain_id: domain.id, content_types: [ "book" ], scholars: [ "Scholar A" ], page: "2", per_page: 21
      )
      expect(TypesenseSearch::HomeBrowseService).not_to have_received(:new)
    end

    it "treats a blank query as browsing" do
      stub_search(TypesenseSearch::HomeBrowseService, empty_search_result)

      get root_path, params: { q: "   " }

      expect(TypesenseSearch::HomeBrowseService).to have_received(:new).with(hash_including(domain_id: domain.id))
    end
  end
end
