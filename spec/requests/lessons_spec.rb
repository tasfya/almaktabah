require 'rails_helper'

RSpec.describe "Lessons API", type: :request do
  let(:domain) { Domain.find_or_create_by(host: "localhost") }
  let(:other_domain) { create(:domain, host: "other.com") }
  let(:scholar) { create(:scholar) }
  let(:series) { create(:series, scholar: scholar) }

  describe "GET /lessons.json" do
    context "with published lessons" do
      let!(:lesson1) { create(:lesson, published: true, series: series) }
      let!(:lesson2) { create(:lesson, published: true, series: series) }

      before do
        lesson1.assign_to(domain)
        lesson2.assign_to(domain)
        host! "localhost"
      end

      it "returns 200 status" do
        get lessons_path(format: :json)
        expect(response).to have_http_status(:ok)
      end

      it "returns correct Content-Type" do
        get lessons_path(format: :json)
        expect(response.content_type).to eq("application/json; charset=utf-8")
      end

      it "returns valid JSON" do
        get lessons_path(format: :json)
        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it "returns expected JSON structure" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)

        lesson_data = json_response.first
        expect(lesson_data).to have_key("id")
        expect(lesson_data).to have_key("title")
        expect(lesson_data).to have_key("description")
        expect(lesson_data).to have_key("position")
        expect(lesson_data).to have_key("published_at")
        expect(lesson_data).to have_key("duration")
        expect(lesson_data).to have_key("series")
        expect(lesson_data).to have_key("scholar_name")
        expect(lesson_data).to have_key("thumbnail_url")
        expect(lesson_data).to have_key("audio_url")
        expect(lesson_data).to have_key("video_url")

        expect(lesson_data["series"]).to have_key("id")
        expect(lesson_data["series"]).to have_key("title")
      end

      it "includes scholar_name from series" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        lesson_data = json_response.first
        expect(lesson_data["scholar_name"]).to eq(scholar.name)
      end
    end

    context "with domain filtering" do
      let!(:lesson_for_domain) { create(:lesson, :without_domain, published: true, series: series) }
      let!(:lesson_for_other_domain) { create(:lesson, :without_domain, published: true, series: series) }

      before do
        lesson_for_domain.assign_to(domain)
        lesson_for_other_domain.assign_to(other_domain)
        host! "localhost"
      end

      it "returns only lessons for the current domain" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)
        expect(json_response.first["id"]).to eq(lesson_for_domain.id)
      end

      it "does not return lessons from other domains" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        lesson_ids = json_response.map { |l| l["id"] }
        expect(lesson_ids).not_to include(lesson_for_other_domain.id)
      end
    end

    context "with pagination" do
      let!(:lessons) { create_list(:lesson, 15, published: true, series: series) }

      before do
        lessons.each { |lesson| lesson.assign_to(domain) }
        host! "localhost"
      end

      it "returns paginated results (12 items per page)" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(12)
      end

      it "returns second page" do
        get lessons_path(format: :json, page: 2)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(3)
      end
    end

    context "with empty results" do
      before do
        host! "localhost"
      end

      it "returns empty array when no lessons exist" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to eq([])
      end
    end

    context "with unpublished lessons" do
      let!(:unpublished_lesson) { create(:lesson, published: false, series: series) }

      before do
        unpublished_lesson.assign_to(domain)
        host! "localhost"
      end

      it "does not return unpublished lessons" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(0)
      end
    end

    context "when domain is not found" do
      before do
        host! "nonexistent.com"
      end

      it "returns empty array" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to eq([])
      end
    end

    context "with media attachments" do
      let!(:lesson_with_attachments) { create(:lesson, :with_video, published: true, series: series) }

      before do
        lesson_with_attachments.assign_to(domain)
        host! "localhost"
      end

      it "includes thumbnail_url when thumbnail is attached" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        lesson_data = json_response.first
        expect(lesson_data["thumbnail_url"]).to be_present
      end

      it "includes audio_url when audio is attached" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        lesson_data = json_response.first
        expect(lesson_data["audio_url"]).to be_present
      end

      it "includes video_url when video is attached" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        lesson_data = json_response.first
        expect(lesson_data["video_url"]).to be_present
      end
    end

    context "with position ordering" do
      let!(:lesson1) { create(:lesson, published: true, series: series, position: 2) }
      let!(:lesson2) { create(:lesson, published: true, series: series, position: 1) }

      before do
        lesson1.assign_to(domain)
        lesson2.assign_to(domain)
        host! "localhost"
      end

      it "orders lessons by position" do
        get lessons_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(2)
        expect(json_response.first["position"]).to eq(1)
        expect(json_response.second["position"]).to eq(2)
      end
    end
  end
end
