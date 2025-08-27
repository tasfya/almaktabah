require 'rails_helper'

RSpec.describe BenefitsController, type: :controller do
  before(:each) do
    request.host = "localhost"
  end
  let!(:domain) { create(:domain, host: "localhost") }
  let(:published_benefit) { create(:benefit, published: true, published_at: 1.day.ago) }
  let(:unpublished_benefit) { create(:benefit, published: false) }

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns @benefits and @pagy" do
      create_list(:benefit, 5, published: true, published_at: 1.day.ago)

      get :index

      expect(assigns(:benefits)).to be_present
      expect(assigns(:pagy)).to be_present
      expect(assigns(:q)).to be_present
    end

    it "only includes published benefits" do
      published_benefit
      unpublished_benefit

      get :index

      expect(assigns(:benefits)).to include(published_benefit)
      expect(assigns(:benefits)).not_to include(unpublished_benefit)
    end

    it "orders benefits by published_at field descending" do
      create(:benefit, published: true, published_at: 2.days.ago)
      create(:benefit, published: true, published_at: 1.day.ago)

      get :index

      benefits = assigns(:benefits)
      expect(benefits.first.published_at).to be >= benefits.last.published_at
    end

    it "paginates benefits with limit of 12" do
      create_list(:benefit, 15, published: true, published_at: 1.day.ago)

      get :index

      expect(assigns(:benefits).count).to eq(12)
      expect(assigns(:pagy).limit).to eq(12)
    end

    it "supports ransack search parameters" do
      matching_benefit = create(:benefit, title: "Test Search", published: true, published_at: 1.day.ago)
      non_matching_benefit = create(:benefit, title: "Other Benefit", published: true, published_at: 1.day.ago)

      get :index, params: { q: { title_cont: "Test" } }

      expect(assigns(:benefits)).to include(matching_benefit)
      expect(assigns(:benefits)).not_to include(non_matching_benefit)
    end

    it "sets up benefits breadcrumbs" do
      expect(controller).to receive(:breadcrumb_for).with(
        I18n.t("breadcrumbs.benefits"),
        benefits_path
      )

      get :index
    end
  end

  describe "GET #show" do
    context "when benefit is published" do
      it "returns a successful response" do
        get :show, params: { id: published_benefit.id }
        expect(response).to be_successful
      end

      it "assigns the requested benefit" do
        get :show, params: { id: published_benefit.id }
        expect(assigns(:benefit)).to eq(published_benefit)
      end

      it "sets up show breadcrumbs" do
        expect(controller).to receive(:breadcrumb_for).with(
          I18n.t("breadcrumbs.benefits"),
          benefits_path
        )
        expect(controller).to receive(:breadcrumb_for).with(
          published_benefit.title,
          benefit_path(published_benefit)
        )

        get :show, params: { id: published_benefit.id }
      end
    end

    context "when benefit is not published" do
      it "redirects to benefits index" do
        get :show, params: { id: unpublished_benefit.id }
        expect(response).to redirect_to(benefits_path)
      end

      it "shows not found alert" do
        get :show, params: { id: unpublished_benefit.id }
        expect(flash[:alert]).to eq(I18n.t("messages.benefit_not_found"))
      end
    end

    context "when benefit does not exist" do
      it "redirects to benefits index" do
        get :show, params: { id: 99999 }
        expect(response).to redirect_to(benefits_path)
      end

      it "shows not found alert" do
        get :show, params: { id: 99999 }
        expect(flash[:alert]).to eq(I18n.t("messages.benefit_not_found"))
      end
    end
  end
end
