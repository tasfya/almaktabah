require 'rails_helper'

RSpec.describe FatwasController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end
  let!(:domain) { create(:domain, host: "localhost") }
  let(:published_fatwa) { create(:fatwa, published: true, published_at: 1.day.ago) }
  let(:unpublished_fatwa) { create(:fatwa, published: false) }

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns @fatwas and @pagy" do
      create_list(:fatwa, 5, published: true, published_at: 1.day.ago)

      get :index

      expect(assigns(:fatwas)).to be_present
      expect(assigns(:pagy)).to be_present
      expect(assigns(:q)).to be_present
    end

    it "only includes published fatwas" do
      published_fatwa
      unpublished_fatwa

      get :index

      expect(assigns(:fatwas)).to include(published_fatwa)
      expect(assigns(:fatwas)).not_to include(unpublished_fatwa)
    end

    it "orders fatwas by published_at field descending" do
      create(:fatwa, published: true, published_at: 2.days.ago)
      create(:fatwa, published: true, published_at: 1.day.ago)

      get :index

      fatwas = assigns(:fatwas)
      expect(fatwas.first.published_at).to be >= fatwas.last.published_at
    end

    it "paginates fatwas with limit of 12" do
      create_list(:fatwa, 15, published: true, published_at: 1.day.ago)

      get :index

      expect(assigns(:fatwas).count).to eq(12)
      expect(assigns(:pagy).limit).to eq(12)
    end

    it "supports ransack search parameters" do
      matching_fatwa = create(:fatwa, title: "Test Search", published: true, published_at: 1.day.ago)
      non_matching_fatwa = create(:fatwa, title: "Other Fatwa", published: true, published_at: 1.day.ago)

      get :index, params: { q: { title_cont: "Test" } }

      expect(assigns(:fatwas)).to include(matching_fatwa)
      expect(assigns(:fatwas)).not_to include(non_matching_fatwa)
    end

    it "sets up fatwas breadcrumbs" do
      expect(controller).to receive(:breadcrumb_for).with(
        I18n.t("breadcrumbs.fatwas"),
        fatwas_path
      )

      get :index
    end
  end

  describe "GET #show" do
    context "when fatwa exists" do
      it "returns a successful response" do
        get :show, params: { id: published_fatwa.id }
        expect(response).to be_successful
      end

      it "assigns the requested fatwa" do
        get :show, params: { id: published_fatwa.id }
        expect(assigns(:fatwa)).to eq(published_fatwa)
      end

      it "sets up show breadcrumbs" do
        expect(controller).to receive(:breadcrumb_for).with(
          I18n.t("breadcrumbs.fatwas"),
          fatwas_path
        )
        expect(controller).to receive(:breadcrumb_for).with(
          published_fatwa.title,
          fatwa_path(published_fatwa)
        )

        get :show, params: { id: published_fatwa.id }
      end
    end

    context "when fatwa does not exist" do
      it "redirects to fatwas index" do
        get :show, params: { id: 99999 }
        expect(response).to redirect_to(fatwas_path)
      end

      it "shows not found alert" do
        get :show, params: { id: 99999 }
        expect(flash[:alert]).to eq(I18n.t("messages.fatwa_not_found"))
      end
    end
  end
end
