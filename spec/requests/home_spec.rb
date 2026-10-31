# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }

  before do
    host! "localhost"
    stub_typesense_search(empty_search_result)
  end

  describe "GET /" do
    it "renders the search page" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(search_page_rendered?).to be(true)
    end
  end
end
