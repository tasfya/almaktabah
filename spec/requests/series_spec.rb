require 'rails_helper'

RSpec.describe "Series API", type: :request do
  let(:domain) { Domain.find_or_create_by(host: "localhost") }
  let(:other_domain) { create(:domain, host: "other.com") }
  let(:scholar) { create(:scholar) }

  describe "GET /series.json" do
    context "with published series" do
      let!(:series1) { create(:series, published: true, scholar: scholar) }
      let!(:series2) { create(:series, published: true, scholar: scholar) }

      before do
        series1.assign_to(domain)
        series2.assign_to(domain)
        host! "localhost"
      end

      it "returns 200 status" do
        get series_index_path(format: :json)
        expect(response).to have_http_status(:ok)
      end

      it "returns correct Content-Type" do
        get series_index_path(format: :json)
        expect(response.content_type).to eq("application/json; charset=utf-8")
      end

      it "returns valid JSON" do
        get series_index_path(format: :json)
        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it "returns expected JSON structure" do
        get series_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)

        series_data = json_response.first
        expect(series_data).to have_key("id")
        expect(series_data).to have_key("title")
        expect(series_data).to have_key("description")
        expect(series_data).to have_key("published_at")
        expect(series_data).to have_key("category")
        expect(series_data).to have_key("scholar")
        expect(series_data["scholar"]).to have_key("id")
        expect(series_data["scholar"]).to have_key("name")
      end

      it "includes scholar information" do
        get series_index_path(format: :json)
        json_response = JSON.parse(response.body)

        series_data = json_response.first
        expect(series_data["scholar"]["id"]).to eq(scholar.id)
        expect(series_data["scholar"]["name"]).to eq(scholar.name)
      end
    end

    context "with domain filtering" do
      let!(:series_for_domain) { create(:series, :without_domain, published: true, scholar: scholar) }
      let!(:series_for_other_domain) { create(:series, :without_domain, published: true, scholar: scholar) }

      before do
        series_for_domain.assign_to(domain)
        series_for_other_domain.assign_to(other_domain)
        host! "localhost"
      end

      it "returns only series for the current domain" do
        get series_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)
        expect(json_response.first["id"]).to eq(series_for_domain.id)
      end

      it "does not return series from other domains" do
        get series_index_path(format: :json)
        json_response = JSON.parse(response.body)

        series_ids = json_response.map { |s| s["id"] }
        expect(series_ids).not_to include(series_for_other_domain.id)
      end
    end

    context "with pagination" do
      let!(:series_list) { create_list(:series, 15, published: true, scholar: scholar) }

      before do
        series_list.each { |series| series.assign_to(domain) }
        host! "localhost"
      end

      it "returns paginated results (12 items per page)" do
        get series_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(12)
      end

      it "returns second page" do
        get series_index_path(format: :json, page: 2)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(3)
      end
    end

    context "with empty results" do
      before do
        domain
        host! "localhost"
      end

      it "returns empty array when no series exist" do
        get series_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to eq([])
      end
    end

    context "with unpublished series" do
      let!(:unpublished_series) { create(:series, published: false, scholar: scholar) }

      before do
        unpublished_series.assign_to(domain)
        host! "localhost"
      end

      it "does not return unpublished series" do
        get series_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(0)
      end
    end


    context "with ordering by published_at" do
      let!(:older_series) { create(:series, published: true, scholar: scholar, published_at: 2.days.ago) }
      let!(:newer_series) { create(:series, published: true, scholar: scholar, published_at: 1.day.ago) }

      before do
        older_series.assign_to(domain)
        newer_series.assign_to(domain)
        host! "localhost"
      end

      it "orders series by published_at descending" do
        get series_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(2)
        expect(json_response.first["id"]).to eq(newer_series.id)
        expect(json_response.second["id"]).to eq(older_series.id)
      end
    end
  end
end
