# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Fatwas", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }
  let(:published_fatwa) { create(:fatwa, published: true, published_at: 1.day.ago) }

  before { host! "localhost" }

  describe "GET /fatwas" do
    let(:collection_search) { instance_double(TypesenseSearch::CollectionSearchService, call: empty_search_result) }

    before { allow(TypesenseSearch::CollectionSearchService).to receive(:new).and_return(collection_search) }

    it "searches the fatwa collection on the request's domain, 15 per page by default" do
      get fatwas_path

      expect(TypesenseSearch::CollectionSearchService).to have_received(:new).with(
        collection: "fatwa", query: nil, domain_id: domain.id, scholars: nil, page: nil, per_page: 15
      )
    end

    it "passes the query, scholar filter and paging params through" do
      get fatwas_path, params: { q: " tawhid ", scholars: [ "Scholar A" ], page: "3", per_page: "9" }

      expect(TypesenseSearch::CollectionSearchService).to have_received(:new).with(
        collection: "fatwa", query: "tawhid", domain_id: domain.id, scholars: [ "Scholar A" ], page: "3", per_page: 9
      )
    end

    it "renders the search page" do
      get fatwas_path
      expect(response).to have_http_status(:ok)
      expect(search_page_rendered?).to be(true)
    end

    it "shows the fatwas breadcrumb" do
      get fatwas_path
      expect(breadcrumb_trail).to eq([ [ I18n.t("breadcrumbs.fatwas"), nil ] ])
    end
  end

  describe "GET /:scholar_id/fatwas/:id" do
    context "when fatwa exists" do
      it "shows the fatwa" do
        get fatwa_path(published_fatwa.scholar.slug, published_fatwa.to_param)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(ERB::Util.html_escape(published_fatwa.title))
      end

      it "shows the fatwas index and fatwa breadcrumbs" do
        get fatwa_path(published_fatwa.scholar.slug, published_fatwa.to_param)
        expect(breadcrumb_trail).to eq([
          [ I18n.t("breadcrumbs.fatwas"), fatwas_path ],
          [ published_fatwa.title, nil ]
        ])
      end
    end

    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = published_fatwa.scholar.slug
        published_fatwa.scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get fatwa_path(old_slug, published_fatwa.to_param)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(fatwa_path(published_fatwa.scholar, published_fatwa))
      end
    end

    context "when accessed via old fatwa slug" do
      it "redirects to canonical slug URL with 301" do
        old_slug = published_fatwa.slug
        published_fatwa.update!(title: "New Unique Fatwa Title #{SecureRandom.hex(4)}")

        get fatwa_path(published_fatwa.scholar.slug, old_slug)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(fatwa_path(published_fatwa.scholar, published_fatwa))
      end
    end

    context "when scholar does not exist" do
      it "redirects to fatwas index" do
        get fatwa_path("nonexistent-scholar", published_fatwa.to_param)
        expect(response).to redirect_to(fatwas_path)
        expect(flash[:alert]).to eq(I18n.t("messages.fatwa_not_found"))
      end
    end

    context "when fatwa does not exist" do
      it "redirects to fatwas index" do
        get fatwa_path(scholar.slug, 99999)
        expect(response).to redirect_to(fatwas_path)
        expect(flash[:alert]).to eq(I18n.t("messages.fatwa_not_found"))
      end
    end
  end

  describe "GET /fatwas/:id (legacy)" do
    it "redirects to canonical fatwa URL with 301" do
      get legacy_fatwa_path(published_fatwa.slug)
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(fatwa_path(published_fatwa.scholar, published_fatwa))
    end

    it "redirects to fatwas index when not found" do
      get legacy_fatwa_path("nonexistent-slug")
      expect(response).to redirect_to(fatwas_path)
      expect(flash[:alert]).to eq(I18n.t("messages.fatwa_not_found"))
    end
  end
end
