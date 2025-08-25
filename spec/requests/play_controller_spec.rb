require 'rails_helper'

RSpec.describe PlayController, type: :request do
  before(:each) do
    Faker::UniqueGenerator.clear
  end

  let(:domain) { create(:domain, host: "localhost") }
  let(:other_domain) { create(:domain) }
  let(:headers) { { "HTTP_HOST" => "localhost" } }

  describe "POST #show" do
    context "with a lesson" do
      let!(:published_lesson) { create(:lesson, published: true, published_at: 1.day.ago) }
      let!(:unpublished_lesson) { create(:lesson, published: false) }

      before do
        create(:domain_assignment, domain: domain, assignable: published_lesson)
        create(:domain_assignment, domain: domain, assignable: unpublished_lesson)
      end

      it "returns a successful response for published lesson" do
        post "/play/lesson/#{published_lesson.id}", headers: headers
        expect(response).to be_successful
      end

      it "renders the lesson in the player" do
        post "/play/lesson/#{published_lesson.id}", headers: headers
        expect(response.body).to include(published_lesson.title)
        expect(response.body).to include("audio-player")
      end

      it "renders the play/show template" do
        post "/play/lesson/#{published_lesson.id}", headers: headers
        expect(response).to render_template("play/show")
      end

      it "redirects to root_path when lesson is not published" do
        post "/play/lesson/#{unpublished_lesson.id}", headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end

      it "redirects to root_path when lesson not found" do
        post "/play/lesson/99999", headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end
    end

    context "with a lecture" do
      let!(:published_lecture) { create(:lecture, published: true, published_at: 1.day.ago) }
      let!(:unpublished_lecture) { create(:lecture, published: false) }

      before do
        create(:domain_assignment, domain: domain, assignable: published_lecture)
        create(:domain_assignment, domain: domain, assignable: unpublished_lecture)
      end

      it "returns a successful response for published lecture" do
        post "/play/lecture/#{published_lecture.id}", headers: headers
        expect(response).to be_successful
      end

      it "renders the lecture in the player" do
        post "/play/lecture/#{published_lecture.id}", headers: headers
        expect(response.body).to include(published_lecture.title)
        expect(response.body).to include("audio-player")
      end

      it "redirects to root_path when lecture is not published" do
        post "/play/lecture/#{unpublished_lecture.id}", headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end

      it "redirects to root_path when lecture not found" do
        post "/play/lecture/99999", headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end

    context "with a benefit" do
      let!(:published_benefit) { create(:benefit, published: true, published_at: 1.day.ago) }
      let!(:unpublished_benefit) { create(:benefit, published: false) }

      before do
        create(:domain_assignment, domain: domain, assignable: published_benefit)
        create(:domain_assignment, domain: domain, assignable: unpublished_benefit)
      end

      it "returns a successful response for published benefit" do
        post "/play/benefit/#{published_benefit.id}", headers: headers
        expect(response).to be_successful
      end

      it "renders the benefit in the player" do
        post "/play/benefit/#{published_benefit.id}", headers: headers
        expect(response.body).to include(published_benefit.title)
        expect(response.body).to include("audio-player")
      end

      it "redirects to root_path when benefit is not published" do
        post "/play/benefit/#{unpublished_benefit.id}", headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.benefit_not_found"))
      end

      it "redirects to root_path when benefit not found" do
        post "/play/benefit/99999", headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.benefit_not_found"))
      end
    end

    context "with invalid resource type" do
      it "redirects to root_path with invalid resource alert" do
        post "/play/invalid_type/1", headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.invalid_resource"))
      end
    end
  end

  describe "DELETE #stop" do
    it "returns a successful response" do
      delete "/play/stop", headers: headers
      expect(response).to be_successful
    end

    it "renders turbo_stream response" do
      delete "/play/stop", headers: headers
      expect(response.body).to include('turbo-stream')
      expect(response.body).to include('update')
      expect(response.body).to include('audio')
    end

    it "clears the audio element" do
      delete "/play/stop", headers: headers
      expect(response.body).to include('<turbo-stream action="update" target="audio-player">')
    end
  end

  describe "private methods" do
    let(:controller_instance) { described_class.new }

    describe "#resource_class" do
      it "returns Lesson for 'Lesson'" do
        expect(controller_instance.send(:resource_class, "Lesson")).to eq(Lesson)
      end

      it "returns Lecture for 'Lecture'" do
        expect(controller_instance.send(:resource_class, "Lecture")).to eq(Lecture)
      end

      it "returns Benefit for 'Benefit'" do
        expect(controller_instance.send(:resource_class, "Benefit")).to eq(Benefit)
      end

      it "raises error for invalid resource type" do
        expect {
          controller_instance.send(:resource_class, "InvalidType")
        }.to raise_error("Invalid resource type: InvalidType")
      end
    end

    describe "#set_resource" do
      let!(:published_lesson) { create(:lesson, published: true, published_at: 1.day.ago) }

      before do
        create(:domain_assignment, domain: domain, assignable: published_lesson)
      end

      it "redirects when resource not found" do
        post "/play/lesson/99999", headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end

      it "redirects when invalid resource type" do
        post "/play/invalid/1", headers: headers
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.invalid_resource"))
      end
    end
  end
end
