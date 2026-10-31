# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Play", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }

  before { host! "localhost" }

  describe "GET /play/:resource_type/:id" do
    context "with a lesson" do
      let!(:published_lesson) { create(:lesson, published: true, published_at: 1.day.ago) }
      let!(:unpublished_lesson) { create(:lesson, published: false) }

      before do
        create(:domain_assignment, domain: domain, assignable: published_lesson)
        create(:domain_assignment, domain: domain, assignable: unpublished_lesson)
      end

      it "renders the player page for a published lesson" do
        get play_path("lesson", published_lesson.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(ERB::Util.html_escape(published_lesson.title))
      end

      it "updates the audio player over turbo stream" do
        get play_path("lesson", published_lesson.id), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include('<turbo-stream action="update" target="audio-player">')
        expect(response.body).to include(ERB::Util.html_escape(published_lesson.title))
      end

      it "redirects to root_path when lesson is not published" do
        get play_path("lesson", unpublished_lesson.id)
        expect(response).to be_not_found_page(I18n.t("messages.lesson_not_found"), back_to: root_path)
      end

      it "redirects to root_path when lesson not found" do
        get play_path("lesson", 99999)
        expect(response).to be_not_found_page(I18n.t("messages.lesson_not_found"), back_to: root_path)
      end
    end

    context "with a lecture" do
      let!(:published_lecture) { create(:lecture, published: true, published_at: 1.day.ago) }
      let!(:unpublished_lecture) { create(:lecture, published: false) }

      before do
        create(:domain_assignment, domain: domain, assignable: published_lecture)
        create(:domain_assignment, domain: domain, assignable: unpublished_lecture)
      end

      it "renders the player page for a published lecture" do
        get play_path("lecture", published_lecture.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(ERB::Util.html_escape(published_lecture.title))
      end

      it "redirects to root_path when lecture is not published" do
        get play_path("lecture", unpublished_lecture.id)
        expect(response).to be_not_found_page(I18n.t("messages.lecture_not_found"), back_to: root_path)
      end

      it "redirects to root_path when lecture not found" do
        get play_path("lecture", 99999)
        expect(response).to be_not_found_page(I18n.t("messages.lecture_not_found"), back_to: root_path)
      end
    end

    context "with invalid resource type" do
      it "redirects to root_path with invalid resource alert" do
        get play_path("invalid_type", 1)
        expect(response).to be_not_found_page(I18n.t("messages.invalid_resource"), back_to: root_path)
      end
    end
  end

  describe "GET /play/stop" do
    it "clears the audio player over turbo stream" do
      get stop_play_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<turbo-stream action="update" target="audio-player">')
    end
  end
end
