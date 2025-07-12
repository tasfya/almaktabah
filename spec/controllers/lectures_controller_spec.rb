require 'rails_helper'

RSpec.describe LecturesController, type: :controller do
  let(:domain) { create(:domain) }
  let(:other_domain) { create(:domain) }

  before do
    allow(controller).to receive(:set_domain)
    controller.instance_variable_set(:@domain, domain)
  end

  describe "GET #index" do
    let!(:lecture1) { create(:lecture) }
    let!(:lecture2) { create(:lecture) }
    let!(:lecture3) { create(:lecture, published: false) }
    let!(:other_domain_lecture) { create(:lecture) }

    before do
      # Associate lectures with current domain
      create(:domain_assignment, domain: domain, assignable: lecture1)
      create(:domain_assignment, domain: domain, assignable: lecture2)
      create(:domain_assignment, domain: domain, assignable: lecture3)

      # Associate lecture with other domain
      create(:domain_assignment, domain: other_domain, assignable: other_domain_lecture)
    end

    context "HTML format" do
      it "assigns published lectures for current domain" do
        get :index

        expect(assigns(:lectures)).to include(lecture1, lecture2)
        expect(assigns(:lectures)).not_to include(lecture3) # unpublished
        expect(assigns(:lectures)).not_to include(other_domain_lecture) # other domain
      end



      it "sets up ransack search" do
        get :index, params: { q: { title_cont: lecture1.title } }

        expect(assigns(:q)).to be_present
        expect(assigns(:q).title_cont).to eq(lecture1.title)
      end

      it "renders index template" do
        get :index

        expect(response).to render_template(:index)
        expect(response).to have_http_status(:ok)
      end

      it "sets up breadcrumbs" do
        expect(controller).to receive(:breadcrumb_for).with(I18n.t("breadcrumbs.lectures"), lectures_path)

        get :index
      end
    end

    context "JSON format" do
      it "returns lectures as JSON" do
        get :index, format: :json

        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(2) # only published lectures for current domain
      end
    end
  end

  describe "GET #show" do
    let!(:lecture) { create(:lecture) }
    let!(:related_lecture1) { create(:lecture) }
    let!(:related_lecture2) { create(:lecture) }
    let!(:unrelated_lecture) { create(:lecture) } # different category
    let!(:unpublished_related) { create(:lecture, published: false) }

    before do
      create(:domain_assignment, domain: domain, assignable: lecture)
      create(:domain_assignment, domain: domain, assignable: related_lecture1)
      create(:domain_assignment, domain: domain, assignable: related_lecture2)
      create(:domain_assignment, domain: domain, assignable: unrelated_lecture)
      create(:domain_assignment, domain: domain, assignable: unpublished_related)
    end

    context "when lecture exists and is published" do
      it "assigns the lecture" do
        get :show, params: { id: lecture.id }

        expect(assigns(:lecture)).to eq(lecture)
      end


      it "renders show template" do
        get :show, params: { id: lecture.id }

        expect(response).to render_template(:show)
        expect(response).to have_http_status(:ok)
      end

      it "sets up breadcrumbs" do
        expect(controller).to receive(:breadcrumb_for).with(I18n.t("breadcrumbs.lectures"), lectures_path)
        expect(controller).to receive(:breadcrumb_for).with(lecture.title, lecture_path(lecture))

        get :show, params: { id: lecture.id }
      end
    end

    context "when lecture doesn't exist" do
      it "redirects to lectures index with alert" do
        get :show, params: { id: 999999 }

        expect(response).to redirect_to(lectures_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end

    context "when lecture is unpublished" do
      let!(:unpublished_lecture) { create(:lecture, published: false) }

      before do
        create(:domain_assignment, domain: domain, assignable: unpublished_lecture)
      end

      it "redirects to lectures index with alert" do
        get :show, params: { id: unpublished_lecture.id }

        expect(response).to redirect_to(lectures_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end
  end

  describe "GET #play" do
    let!(:lecture) { create(:lecture) }

    before do
      create(:domain_assignment, domain: domain, assignable: lecture)
    end

    it "assigns the lecture" do
      get :play, params: { id: lecture.id }

      expect(assigns(:lecture)).to eq(lecture)
    end

    it "renders play template" do
      get :play, params: { id: lecture.id }

      expect(response).to render_template(:play)
      expect(response).to have_http_status(:ok)
    end

    context "when lecture doesn't exist" do
      it "redirects to lectures index with alert" do
        get :play, params: { id: 999999 }

        expect(response).to redirect_to(lectures_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end
  end
end
