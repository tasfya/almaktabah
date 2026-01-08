# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomeController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let!(:domain) { create(:domain, host: "localhost") }

  describe "GET #index" do
    before do
      stub_typesense_search(empty_search_result)
    end

    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "renders search/index template" do
      get :index
      expect(response).to render_template("search/index")
    end

    it "assigns search-related instance variables" do
      get :index
      expect(assigns(:results)).not_to be_nil
      expect(assigns(:facets)).not_to be_nil
    end
  end
end
