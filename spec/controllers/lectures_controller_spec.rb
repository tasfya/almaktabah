require 'rails_helper'

RSpec.describe LecturesController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end
  let(:domain) { create(:domain, host: "localhost") }
  let(:other_domain) { create(:domain) }
  let!(:published_lecture) { create(:lecture, published: true, published_at: 1.day.ago) }
  let!(:unpublished_lecture) { create(:lecture, published: false) }

  before do
    allow(controller).to receive(:set_domain)
    controller.instance_variable_set(:@domain, domain)

    create(:domain_assignment, domain: domain, assignable: published_lecture)
    create(:domain_assignment, domain: domain, assignable: unpublished_lecture)
    create(:domain_assignment, domain: other_domain, assignable: create(:lecture, published: true, published_at: 1.day.ago))
  end

  describe "GET #index" do
    context "HTML format" do
      let!(:lecture1) { create(:lecture, published: true, published_at: 1.day.ago) }
      let!(:lecture2) { create(:lecture, published: true, published_at: 2.days.ago) }
      let!(:lecture3) { create(:lecture, published: false) }
      let!(:other_domain_lecture) { create(:lecture, published: true) }

      before do
        [ lecture1, lecture2, lecture3 ].each do |lecture|
          create(:domain_assignment, domain: domain, assignable: lecture)
        end
        create(:domain_assignment, domain: other_domain, assignable: other_domain_lecture)
      end

      it "returns a successful response" do
        get :index
        expect(response).to be_successful
      end

      it "assigns paginated, published lectures for the current domain" do
        get :index

        expect(assigns(:lectures)).to include(lecture1, lecture2)
        expect(assigns(:lectures)).not_to include(lecture3, other_domain_lecture)
        expect(assigns(:pagy)).to be_present
      end

      it "orders lectures by published_at descending" do
        get :index
        lectures = assigns(:lectures)
        expect(lectures.first).to eq(lecture1)
        expect(lectures.last).to eq(lecture2)
      end

      it "paginates lectures with limit of 12" do
        create_list(:lecture, 15, published: true, published_at: 1.day.ago) do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end

        get :index
        expect(assigns(:lectures).count).to eq(12)
        expect(assigns(:pagy).limit).to eq(12)
      end

      it "supports ransack search" do
        matching = create(:lecture, title: "Test Search", published: true)
        non_matching = create(:lecture, title: "Another", published: true)
        [ matching, non_matching ].each do |lecture|
          create(:domain_assignment, domain: domain, assignable: lecture)
        end

        get :index, params: { q: { title_cont: "Test" } }
        expect(assigns(:lectures)).to include(matching)
        expect(assigns(:lectures)).not_to include(non_matching)
      end

      it "sets up breadcrumbs" do
        expect(controller).to receive(:breadcrumb_for).with(I18n.t("breadcrumbs.lectures"), lectures_path)
        get :index
      end

      it "renders index template" do
        get :index
        expect(response).to render_template(:index)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET #show" do
    context "when lecture is published" do
      let!(:same_category) { create(:lecture, category: published_lecture.category, published: true) }
      let!(:other_category) { create(:lecture, category: "Other", published: true) }

      before do
        [ published_lecture, same_category, other_category ].each do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end
      end

      it "shows the lecture" do
        get :show, params: { id: published_lecture.id }
        expect(response).to be_successful
        expect(assigns(:lecture)).to eq(published_lecture)
      end

      it "assigns related lectures from the same category" do
        get :show, params: { id: published_lecture.id }
        related = assigns(:related_lectures)
        expect(related).to include(same_category)
        expect(related).not_to include(published_lecture, other_category)
      end

      it "limits related lectures to 4" do
        create_list(:lecture, 6, category: published_lecture.category, published: true) do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end

        get :show, params: { id: published_lecture.id }
        expect(assigns(:related_lectures).count).to eq(4)
      end

      it "sets up breadcrumbs" do
        expect(controller).to receive(:breadcrumb_for).with(I18n.t("breadcrumbs.lectures"), lectures_path)
        expect(controller).to receive(:breadcrumb_for).with(published_lecture.title, lecture_path(published_lecture))
        get :show, params: { id: published_lecture.id }
      end
    end

    context "when lecture is unpublished or not found" do
      it "redirects and shows alert for unpublished lecture" do
        create(:domain_assignment, domain: domain, assignable: unpublished_lecture)

        get :show, params: { id: unpublished_lecture.id }
        expect(response).to redirect_to(lectures_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end

      it "redirects and shows alert for missing lecture" do
        get :show, params: { id: 999999 }
        expect(response).to redirect_to(lectures_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end
  end

  describe "GET #play" do
    context "when lecture is published" do
      before do
        create(:domain_assignment, domain: domain, assignable: published_lecture)
      end

      it "renders play template" do
        get :play, params: { id: published_lecture.id }
        expect(response).to render_template(:play)
        expect(response).to have_http_status(:ok)
      end

      it "assigns lecture" do
        get :play, params: { id: published_lecture.id }
        expect(assigns(:lecture)).to eq(published_lecture)
      end
    end

    context "when lecture is unpublished or missing" do
      before do
        create(:domain_assignment, domain: domain, assignable: unpublished_lecture)
      end

      it "redirects and shows alert for unpublished" do
        get :play, params: { id: unpublished_lecture.id }
        expect(response).to redirect_to(lectures_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end

      it "redirects and shows alert for missing" do
        get :play, params: { id: 999999 }
        expect(response).to redirect_to(lectures_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end
  end
end
