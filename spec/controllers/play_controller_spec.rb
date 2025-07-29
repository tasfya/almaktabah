require 'rails_helper'

RSpec.describe PlayController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let(:domain) { create(:domain, host: "localhost") }
  let(:other_domain) { create(:domain) }

  before do
    allow(controller).to receive(:set_domain)
    controller.instance_variable_set(:@domain, domain)
  end

  describe "POST #show" do
    context "with a lesson" do
      let!(:published_lesson) { create(:lesson, published: true, published_at: 1.day.ago) }
      let!(:unpublished_lesson) { create(:lesson, published: false) }

      before do
        create(:domain_assignment, domain: domain, assignable: published_lesson)
        create(:domain_assignment, domain: domain, assignable: unpublished_lesson)
      end

      it "returns a successful response for published lesson" do
        post :show, params: { resource_type: "lesson", id: published_lesson.id }
        expect(response).to be_successful
      end

      it "assigns the requested lesson" do
        post :show, params: { resource_type: "lesson", id: published_lesson.id }
        expect(assigns(:resource)).to eq(published_lesson)
      end

      it "renders the play/show template" do
        post :show, params: { resource_type: "lesson", id: published_lesson.id }
        expect(response).to render_template("play/show")
      end

      it "redirects to root_path when lesson is not published" do
        post :show, params: { resource_type: "lesson", id: unpublished_lesson.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end

      it "redirects to root_path when lesson not found" do
        post :show, params: { resource_type: "lesson", id: 99999 }
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
        post :show, params: { resource_type: "lecture", id: published_lecture.id }
        expect(response).to be_successful
      end

      it "assigns the requested lecture" do
        post :show, params: { resource_type: "lecture", id: published_lecture.id }
        expect(assigns(:resource)).to eq(published_lecture)
      end

      it "redirects to root_path when lecture is not published" do
        post :show, params: { resource_type: "lecture", id: unpublished_lecture.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end

      it "redirects to root_path when lecture not found" do
        post :show, params: { resource_type: "lecture", id: 99999 }
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
        post :show, params: { resource_type: "benefit", id: published_benefit.id }
        expect(response).to be_successful
      end

      it "assigns the requested benefit" do
        post :show, params: { resource_type: "benefit", id: published_benefit.id }
        expect(assigns(:resource)).to eq(published_benefit)
      end

      it "redirects to root_path when benefit is not published" do
        post :show, params: { resource_type: "benefit", id: unpublished_benefit.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.benefit_not_found"))
      end

      it "redirects to root_path when benefit not found" do
        post :show, params: { resource_type: "benefit", id: 99999 }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.benefit_not_found"))
      end
    end

    context "with invalid resource type" do
      it "redirects to root_path with invalid resource alert" do
        post :show, params: { resource_type: "invalid_type", id: 1 }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("messages.invalid_resource"))
      end
    end
  end

  describe "DELETE #stop" do
    it "returns a successful response" do
      delete :stop
      expect(response).to be_successful
    end

    it "renders turbo_stream response" do
      delete :stop
      expect(response.body).to include('turbo-stream')
      expect(response.body).to include('update')
      expect(response.body).to include('audio')
    end

    it "clears the audio element" do
      delete :stop
      expect(response.body).to include('<turbo-stream action="update" target="audio">')
    end
  end

  describe "private methods" do
    describe "#resource_class" do
      it "returns Lesson for 'Lesson'" do
        expect(controller.send(:resource_class, "Lesson")).to eq(Lesson)
      end

      it "returns Lecture for 'Lecture'" do
        expect(controller.send(:resource_class, "Lecture")).to eq(Lecture)
      end

      it "returns Benefit for 'Benefit'" do
        expect(controller.send(:resource_class, "Benefit")).to eq(Benefit)
      end

      it "raises error for invalid resource type" do
        expect {
          controller.send(:resource_class, "InvalidType")
        }.to raise_error("Invalid resource type: InvalidType")
      end
    end

    describe "#set_resource" do
      let!(:published_lesson) { create(:lesson, published: true, published_at: 1.day.ago) }

      before do
        create(:domain_assignment, domain: domain, assignable: published_lesson)
      end

      it "sets @resource when valid resource found" do
        controller.params = ActionController::Parameters.new(
          resource_type: "lesson",
          id: published_lesson.id
        )

        controller.send(:set_resource)
        expect(controller.instance_variable_get(:@resource)).to eq(published_lesson)
      end

      it "redirects when resource not found" do
        controller.params = ActionController::Parameters.new(
          resource_type: "lesson",
          id: 99999
        )

        expect(controller).to receive(:redirect_to).with(root_path, alert: I18n.t("messages.lesson_not_found"))
        controller.send(:set_resource)
      end

      it "redirects when invalid resource type" do
        controller.params = ActionController::Parameters.new(
          resource_type: "invalid",
          id: 1
        )
        expect(controller).to receive(:redirect_to).with(root_path, alert: I18n.t("messages.invalid_resource"))
        controller.send(:set_resource)
      end
    end
  end
end
