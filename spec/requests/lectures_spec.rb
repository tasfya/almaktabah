require 'rails_helper'

RSpec.describe "Lectures API", type: :request do
  let(:domain) { Domain.find_or_create_by(host: "localhost") }
  let(:other_domain) { create(:domain, host: "other.com") }
  let(:scholar) { create(:scholar) }

  describe "GET /lectures.json" do
    context "with published lectures" do
      let!(:lecture1) { create(:lecture, published: true, scholar: scholar, kind: :seremon) }
      let!(:lecture2) { create(:lecture, published: true, scholar: scholar, kind: :conference) }

      before do
        lecture1.assign_to(domain)
        lecture2.assign_to(domain)
        host! "localhost"
      end

      it "returns 200 status" do
        get lectures_path(format: :json)
        expect(response).to have_http_status(:ok)
      end

      it "returns correct Content-Type" do
        get lectures_path(format: :json)
        expect(response.content_type).to eq("application/json; charset=utf-8")
      end

      it "returns valid JSON" do
        get lectures_path(format: :json)
        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it "returns expected JSON structure" do
        get lectures_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)

        lecture_data = json_response.first
        expect(lecture_data).to have_key("id")
        expect(lecture_data).to have_key("title")
        expect(lecture_data).to have_key("description")
        expect(lecture_data).to have_key("category")
        expect(lecture_data).to have_key("kind")
        expect(lecture_data).to have_key("published_at")
        expect(lecture_data).to have_key("duration")
        expect(lecture_data).to have_key("scholar")
        expect(lecture_data).to have_key("thumbnail_url")
        expect(lecture_data).to have_key("audio_url")
        expect(lecture_data).to have_key("video_url")

        expect(lecture_data["scholar"]).to have_key("id")
        expect(lecture_data["scholar"]).to have_key("name")
      end

      it "includes correct kind values" do
        get lectures_path(format: :json)
        json_response = JSON.parse(response.body)

        kinds = json_response.map { |l| l["kind"] }
        expect(kinds).to include("seremon")
        expect(kinds).to include("conference")
      end
    end

    context "with domain filtering" do
      let!(:lecture_for_domain) { create(:lecture, :without_domain, scholar: scholar) }
      let!(:lecture_for_other_domain) { create(:lecture, :without_domain, scholar: scholar) }

      before do
        lecture_for_domain.assign_to(domain)
        lecture_for_other_domain.assign_to(other_domain)
        host! "localhost"
      end

      it "returns only lectures for the current domain" do
        get lectures_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)
        expect(json_response.first["id"]).to eq(lecture_for_domain.id)
      end

      it "does not return lectures from other domains" do
        get lectures_path(format: :json)
        json_response = JSON.parse(response.body)

        lecture_ids = json_response.map { |l| l["id"] }
        expect(lecture_ids).not_to include(lecture_for_other_domain.id)
      end
    end

    context "with pagination" do
      let!(:lectures) { create_list(:lecture, 15, published: true, scholar: scholar) }

      before do
        lectures.each { |lecture| lecture.assign_to(domain) }
        host! "localhost"
      end

      it "returns paginated results (12 items per page)" do
        get lectures_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(12)
      end

      it "returns second page" do
        get lectures_path(format: :json, page: 2)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(3)
      end
    end

    context "with empty results" do
      before do
        domain
        host! "localhost"
      end

      it "returns empty array when no lectures exist" do
        get lectures_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to eq([])
      end
    end

    context "with unpublished lectures" do
      let!(:unpublished_lecture) { create(:lecture, published: false, scholar: scholar) }

      before do
        unpublished_lecture.assign_to(domain)
        host! "localhost"
      end

      it "does not return unpublished lectures" do
        get lectures_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(0)
      end
    end

    context "with media attachments" do
      let!(:lecture_with_attachments) { create(:lecture, published: true, scholar: scholar) }

      before do
        lecture_with_attachments.assign_to(domain)
        host! "localhost"
      end

      it "includes thumbnail_url when thumbnail is attached" do
        get lectures_path(format: :json)
        json_response = JSON.parse(response.body)

        lecture_data = json_response.first
        expect(lecture_data["thumbnail_url"]).to be_present
      end

      it "includes audio_url when audio is attached" do
        get lectures_path(format: :json)
        json_response = JSON.parse(response.body)

        lecture_data = json_response.first
        expect(lecture_data["audio_url"]).to be_present
      end

      it "includes video_url when video is attached" do
        get lectures_path(format: :json)
        json_response = JSON.parse(response.body)

        lecture_data = json_response.first
        expect(lecture_data["video_url"]).to be_present
      end
    end

    context "with different kinds" do
      let!(:seremon_lecture) { create(:lecture, published: true, scholar: scholar, kind: :seremon) }
      let!(:conference_lecture) { create(:lecture, published: true, scholar: scholar, kind: :conference) }
      let!(:benefit_lecture) { create(:lecture, published: true, scholar: scholar, kind: :benefit) }

      before do
        seremon_lecture.assign_to(domain)
        conference_lecture.assign_to(domain)
        benefit_lecture.assign_to(domain)
        host! "localhost"
      end

      it "returns all kinds of lectures" do
        get lectures_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(3)
        kinds = json_response.map { |l| l["kind"] }
        expect(kinds).to include("seremon")
        expect(kinds).to include("conference")
        expect(kinds).to include("benefit")
      end
    end
  end
end
