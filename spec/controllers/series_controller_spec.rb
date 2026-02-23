# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeriesController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }
  let!(:published_series) { create(:series, scholar: scholar, published: true, published_at: 1.day.ago) }

  before do
    allow(controller).to receive(:set_domain)
    controller.instance_variable_set(:@domain, domain)

    create(:domain_assignment, domain: domain, assignable: published_series)
  end

  describe "GET #show" do
    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = scholar.slug
        scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get :show, params: { scholar_id: old_slug, id: published_series.id }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(series_path(scholar, published_series))
      end
    end

    context "when accessed via old series slug" do
      it "redirects to canonical URL with 301" do
        old_slug = published_series.slug
        published_series.update!(title: "New Unique Series Title #{SecureRandom.hex(4)}")

        get :show, params: { scholar_id: scholar.to_param, id: old_slug }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(series_path(scholar, published_series))
      end
    end

    context "when series is not found" do
      it "redirects to series index" do
        get :show, params: { scholar_id: scholar.id, id: 999999 }
        expect(response).to redirect_to(series_index_path)
        expect(flash[:alert]).to eq(I18n.t("messages.series_not_found"))
      end
    end
  end

  describe "GET #legacy_redirect" do
    it "redirects to new series URL with 301" do
      get :legacy_redirect, params: { id: published_series.id }
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(series_path(scholar.slug, published_series))
    end

    it "redirects to series index when not found" do
      get :legacy_redirect, params: { id: 999999 }
      expect(response).to redirect_to(series_index_path)
      expect(flash[:alert]).to eq(I18n.t("messages.series_not_found"))
    end
  end
end
