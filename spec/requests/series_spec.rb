# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Series", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }
  let!(:published_series) { create(:series, scholar: scholar, published: true, published_at: 1.day.ago) }

  before do
    host! "localhost"
    create(:domain_assignment, domain: domain, assignable: published_series)
  end

  describe "GET /:scholar_id/series/:id" do
    it "shows the series" do
      get series_path(scholar, published_series)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ERB::Util.html_escape(published_series.title))
    end

    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = scholar.slug
        scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get series_path(old_slug, published_series.to_param)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(series_path(scholar, published_series))
      end
    end

    context "when accessed via old series slug" do
      it "redirects to canonical URL with 301" do
        old_slug = published_series.slug
        published_series.update!(title: "New Unique Series Title #{SecureRandom.hex(4)}")

        get series_path(scholar.to_param, old_slug)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(series_path(scholar, published_series))
      end
    end

    context "when series is not found" do
      it "redirects to series index" do
        get series_path(scholar.id, 999999)
        expect(response).to redirect_to(series_index_path)
        expect(flash[:alert]).to eq(I18n.t("messages.series_not_found"))
      end
    end
  end

  describe "GET /series/:id (legacy)" do
    it "redirects to new series URL with 301" do
      get "/series/#{published_series.id}"
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(series_path(scholar.slug, published_series))
    end

    it "redirects to series index when not found" do
      get "/series/999999"
      expect(response).to redirect_to(series_index_path)
      expect(flash[:alert]).to eq(I18n.t("messages.series_not_found"))
    end
  end
end
