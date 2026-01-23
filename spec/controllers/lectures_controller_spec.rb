# frozen_string_literal: true

require "rails_helper"

RSpec.describe LecturesController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let(:domain) { create(:domain, host: "localhost") }
  let(:other_domain) { create(:domain) }
  let!(:scholar) { create(:scholar) }
  let!(:published_lecture) { create(:lecture, published: true, published_at: 1.day.ago, scholar: scholar) }
  let!(:unpublished_lecture) { create(:lecture, published: false, scholar: scholar) }

  before do
    allow(controller).to receive(:set_domain)
    controller.instance_variable_set(:@domain, domain)

    create(:domain_assignment, domain: domain, assignable: published_lecture)
    create(:domain_assignment, domain: domain, assignable: unpublished_lecture)
  end

  describe "GET #index" do
    before do
      stub_typesense_search(empty_search_result)
    end

    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "renders search/index template" do
      get :index
      expect(response).to render_template("search/index")
    end

    it "sets up breadcrumbs" do
      expect(controller).to receive(:breadcrumb_for).with(I18n.t("breadcrumbs.lectures"), lectures_path)
      get :index
    end
  end

  describe "GET #show" do
    context "when lecture is published" do
      let!(:same_category) { create(:lecture, category: published_lecture.category, published: true, scholar: scholar) }
      let!(:other_category) { create(:lecture, category: "Other", published: true, scholar: scholar) }

      before do
        [ published_lecture, same_category, other_category ].each do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end
      end

      it "shows the lecture" do
        get :show, params: { scholar_id: scholar.id, kind: published_lecture.kind_for_url, id: published_lecture.id }
        expect(response).to be_successful
        expect(assigns(:lecture)).to eq(published_lecture)
      end

      it "assigns related lectures from the same category" do
        get :show, params: { scholar_id: scholar.id, kind: published_lecture.kind_for_url, id: published_lecture.id }
        related = assigns(:related_lectures)
        expect(related).to include(same_category)
        expect(related).not_to include(published_lecture, other_category)
      end

      it "limits related lectures to 4" do
        create_list(:lecture, 6, category: published_lecture.category, published: true, scholar: scholar) do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end

        get :show, params: { scholar_id: scholar.id, kind: published_lecture.kind_for_url, id: published_lecture.id }
        expect(assigns(:related_lectures).count).to eq(4)
      end

      it "sets up breadcrumbs" do
        expect(controller).to receive(:breadcrumb_for).with(I18n.t("breadcrumbs.lectures"), lectures_path)
        expect(controller).to receive(:breadcrumb_for).with(published_lecture.title, lecture_path(scholar_id: scholar.to_param, kind: published_lecture.kind_for_url, id: published_lecture.to_param))
        get :show, params: { scholar_id: scholar.to_param, kind: published_lecture.kind_for_url, id: published_lecture.to_param }
      end
    end

    context "when lecture is unpublished or not found" do
      it "redirects and shows alert for unpublished lecture" do
        create(:domain_assignment, domain: domain, assignable: unpublished_lecture)

        get :show, params: { scholar_id: scholar.id, kind: unpublished_lecture.kind_for_url, id: unpublished_lecture.id }
        expect(response).to redirect_to(lectures_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end

      it "redirects and shows alert for missing lecture" do
        get :show, params: { scholar_id: scholar.id, kind: I18n.t("activerecord.attributes.lecture.kind.sermon"), id: 999999 }
        expect(response).to redirect_to(lectures_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end
  end
end
