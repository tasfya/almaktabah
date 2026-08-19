# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomeController, type: :controller do
  render_views

  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let!(:domain) { create(:domain, host: "localhost") }

  before do
    allow(DomainContentTypesService).to receive(:for_domain).and_return([])
  end

  describe "GET #index" do
    context "with no query or filters (curated home)" do
      before do
        stub_typesense_search(empty_search_result)
      end

      it "returns a successful response" do
        get :index
        expect(response).to be_successful
      end

      it "renders the home/index template" do
        get :index
        expect(response).to render_template("home/index")
      end

      it "assigns curated home instance variables" do
        get :index
        expect(assigns(:grouped)).not_to be_nil
        expect(assigns(:recent_mixed)).to eq([])
        expect(assigns(:spotlight_scholars)).to eq([])
        expect(assigns(:content_counts)).to eq({})
      end
    end

    context "with a search query" do
      before do
        stub_typesense_search(empty_search_result)
      end

      it "renders the legacy search/index template" do
        get :index, params: { q: "hello" }
        expect(response).to render_template("search/index")
      end

      it "assigns search-related instance variables" do
        get :index, params: { q: "hello" }
        expect(assigns(:results)).not_to be_nil
        expect(assigns(:facets)).not_to be_nil
      end
    end

    context "with scholar or content type filters" do
      before do
        stub_typesense_search(empty_search_result)
      end

      it "renders search/index when a scholar filter is set" do
        get :index, params: { scholars: [ "Some Scholar" ] }
        expect(response).to render_template("search/index")
      end

      it "renders search/index when a content_type filter is set" do
        get :index, params: { content_types: [ "book" ] }
        expect(response).to render_template("search/index")
      end
    end
  end
end
