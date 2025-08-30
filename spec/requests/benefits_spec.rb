require 'rails_helper'

RSpec.describe "Benefits API", type: :request do
  let(:domain) { Domain.find_or_create_by(host: "localhost") }
  let(:other_domain) { create(:domain, host: "other.com") }
  let(:scholar) { create(:scholar) }

  describe "GET /benefits.json" do
    context "with published benefits" do
      let!(:benefit1) { create(:benefit, published: true, scholar: scholar) }
      let!(:benefit2) { create(:benefit, published: true, scholar: nil) }

      before do
        benefit1.assign_to(domain)
        benefit2.assign_to(domain)
        host! "localhost"
      end

      it "returns 200 status" do
        get benefits_path(format: :json)
        expect(response).to have_http_status(:ok)
      end

      it "returns correct Content-Type" do
        get benefits_path(format: :json)
        expect(response.content_type).to eq("application/json; charset=utf-8")
      end

      it "returns valid JSON" do
        get benefits_path(format: :json)
        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it "returns expected JSON structure" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)

        benefit_data = json_response.first
        expect(benefit_data).to have_key("id")
        expect(benefit_data).to have_key("title")
        expect(benefit_data).to have_key("description")
        expect(benefit_data).to have_key("category")
        expect(benefit_data).to have_key("published_at")
        expect(benefit_data).to have_key("duration")
        expect(benefit_data).to have_key("scholar")
        expect(benefit_data).to have_key("thumbnail_url")
        expect(benefit_data).to have_key("audio_url")
        expect(benefit_data).to have_key("video_url")
        expect(benefit_data).to have_key("content_excerpt")
      end

      it "includes scholar data when scholar is present" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        benefit_with_scholar = json_response.find { |b| b["scholar"].present? }
        expect(benefit_with_scholar["scholar"]).to have_key("id")
        expect(benefit_with_scholar["scholar"]).to have_key("name")
      end

      it "returns nil for scholar when no scholar assigned" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        benefit_without_scholar = json_response.find { |b| b["scholar"].nil? }
        expect(benefit_without_scholar["scholar"]).to be_nil
      end
    end

    context "with domain filtering" do
      let!(:benefit_for_domain) { create(:benefit, :without_domain, published: true, scholar: scholar) }
      let!(:benefit_for_other_domain) { create(:benefit, :without_domain, published: true, scholar: scholar) }

      before do
        benefit_for_domain.assign_to(domain)
        benefit_for_other_domain.assign_to(other_domain)
        host! "localhost"
      end

      it "returns only benefits for the current domain" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)
        expect(json_response.first["id"]).to eq(benefit_for_domain.id)
      end

      it "does not return benefits from other domains" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        benefit_ids = json_response.map { |b| b["id"] }
        expect(benefit_ids).not_to include(benefit_for_other_domain.id)
      end
    end

    context "with pagination" do
      let!(:benefits) { create_list(:benefit, 15, published: true, scholar: scholar) }

      before do
        benefits.each { |benefit| benefit.assign_to(domain) }
        host! "localhost"
      end

      it "returns paginated results (12 items per page)" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(12)
      end

      it "returns second page" do
        get benefits_path(format: :json, page: 2)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(3)
      end
    end

    context "with empty results" do
      before do
        domain
        host! "localhost"
      end

      it "returns empty array when no benefits exist" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to eq([])
      end
    end

    context "with unpublished benefits" do
      let!(:unpublished_benefit) { create(:benefit, published: false, scholar: scholar) }

      before do
        unpublished_benefit.assign_to(domain)
        host! "localhost"
      end

      it "does not return unpublished benefits" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(0)
      end
    end

    context "with media attachments" do
      let!(:benefit_with_attachments) { create(:benefit, :with_video, published: true, scholar: scholar) }

      before do
        benefit_with_attachments.assign_to(domain)
        host! "localhost"
      end

      it "includes thumbnail_url when thumbnail is attached" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        benefit_data = json_response.first
        expect(benefit_data["thumbnail_url"]).to be_present
      end

      it "includes audio_url when audio is attached" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        benefit_data = json_response.first
        expect(benefit_data["audio_url"]).to be_present
      end

      it "includes video_url when video is attached" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        benefit_data = json_response.first
        expect(benefit_data["video_url"]).to be_present
      end
    end

    context "with rich text content" do
      let!(:benefit_with_content) { create(:benefit, :published, scholar: scholar, content: "<p>This is a test content</p>") }

      before do
        benefit_with_content.assign_to(domain)
        host! "localhost"
      end

      it "includes content_excerpt" do
        get benefits_path(format: :json)
        json_response = JSON.parse(response.body)

        benefit_data = json_response.first
        expect(benefit_data["content_excerpt"]).to be_present
        expect(benefit_data["content_excerpt"]).to eq("This is a test content")
      end
    end
  end
end
