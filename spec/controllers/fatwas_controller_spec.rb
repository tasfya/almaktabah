# frozen_string_literal: true

require "rails_helper"

RSpec.describe FatwasController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let!(:domain) { create(:domain, host: "localhost") }
  let(:published_fatwa) { create(:fatwa, published: true, published_at: 1.day.ago) }

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

    context "when accessed via old slug" do
      it "redirects to canonical slug URL with 301" do
        old_slug = published_fatwa.slug
        published_fatwa.update!(title: "New Unique Fatwa Title #{SecureRandom.hex(4)}")

        get :show, params: { id: old_slug }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(fatwa_path(published_fatwa))
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
