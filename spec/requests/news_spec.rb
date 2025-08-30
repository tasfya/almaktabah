require 'rails_helper'

RSpec.describe "News API", type: :request do
  let(:domain) { Domain.find_or_create_by(host: "localhost") }
  let(:other_domain) { create(:domain, host: "other.com") }

  describe "GET /news.json" do
    context "with published news" do
      let!(:news1) { create(:news, published: true) }
      let!(:news2) { create(:news, published: true) }

      before do
        news1.assign_to(domain)
        news2.assign_to(domain)
        host! "localhost"
      end

      it "returns 200 status" do
        get news_index_path(format: :json)
        expect(response).to have_http_status(:ok)
      end

      it "returns correct Content-Type" do
        get news_index_path(format: :json)
        expect(response.content_type).to eq("application/json; charset=utf-8")
      end

      it "returns valid JSON" do
        get news_index_path(format: :json)
        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it "returns expected JSON structure" do
        get news_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)

        news_data = json_response.first
        expect(news_data).to have_key("id")
        expect(news_data).to have_key("title")
        expect(news_data).to have_key("description")
        expect(news_data).to have_key("slug")
        expect(news_data).to have_key("published_at")
        expect(news_data).to have_key("content_excerpt")
        expect(news_data).to have_key("thumbnail_url")
      end

      it "includes slug in response" do
        get news_index_path(format: :json)
        json_response = JSON.parse(response.body)

        news_data = json_response.first
        expect(news_data["slug"]).to be_present
      end
    end

    context "with domain filtering" do
      let!(:news_for_domain) { create(:news, :without_domain, published: true) }
      let!(:news_for_other_domain) { create(:news, :without_domain, published: true) }

      before do
        news_for_domain.assign_to(domain)
        news_for_other_domain.assign_to(other_domain)
        host! "localhost"
      end

      it "returns only news for the current domain" do
        get news_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)
        expect(json_response.first["id"]).to eq(news_for_domain.id)
      end

      it "does not return news from other domains" do
        get news_index_path(format: :json)
        json_response = JSON.parse(response.body)

        news_ids = json_response.map { |n| n["id"] }
        expect(news_ids).not_to include(news_for_other_domain.id)
      end
    end

    context "with pagination" do
      let!(:news_items) { create_list(:news, 15, published: true) }

      before do
        news_items.each { |news| news.assign_to(domain) }
        host! "localhost"
      end

      it "returns paginated results (12 items per page)" do
        get news_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(12)
      end

      it "returns second page" do
        get news_index_path(format: :json, page: 2)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(3)
      end
    end

    context "with empty results" do
      before do
        domain
        host! "localhost"
      end

      it "returns empty array when no news exist" do
        get news_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to eq([])
      end
    end

    context "with unpublished news" do
      let!(:unpublished_news) { create(:news, published: false) }

      before do
        unpublished_news.assign_to(domain)
        host! "localhost"
      end

      it "does not return unpublished news" do
        get news_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(0)
      end
    end

    context "with thumbnail attachment" do
      let!(:news_with_thumbnail) { create(:news, published: true) }

      before do
        news_with_thumbnail.assign_to(domain)
        host! "localhost"
      end

      it "includes thumbnail_url when thumbnail is attached" do
        get news_index_path(format: :json)
        json_response = JSON.parse(response.body)

        news_data = json_response.first
        expect(news_data["thumbnail_url"]).to be_present
      end
    end

    context "with rich text content" do
      let!(:news_with_content) { create(:news, :published, content: "<p>This is a test news content</p>") }

      before do
        news_with_content.assign_to(domain)
        host! "localhost"
      end

      it "includes content_excerpt" do
        get news_index_path(format: :json)
        json_response = JSON.parse(response.body)

        news_data = json_response.first
        expect(news_data["content_excerpt"]).to be_present
        expect(news_data["content_excerpt"]).to eq("This is a test news content")
      end
    end

    context "with ordering" do
      let!(:older_news) { create(:news, published: true, published_at: 2.days.ago) }
      let!(:newer_news) { create(:news, published: true, published_at: 1.day.ago) }

      before do
        older_news.assign_to(domain)
        newer_news.assign_to(domain)
        host! "localhost"
      end

      it "orders news by published_at descending" do
        get news_index_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(2)
        expect(json_response.first["id"]).to eq(newer_news.id)
        expect(json_response.second["id"]).to eq(older_news.id)
      end
    end
  end
end
