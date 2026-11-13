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

    context "when the series has the explained book's PDF" do
      before { published_series.explainable.attach(io: File.open(Rails.root.join("spec/files/sample.pdf")), filename: "matn.pdf", content_type: "application/pdf") }

      it "links to the PDF with its label" do
        get series_path(scholar, published_series)

        link = html.at_css("article a[target='_blank'][href*='/rails/active_storage/']")
        expect(link).to be_present
        expect(link.text).to include(I18n.t("series.show.explainable_pdf"))
      end

      it "leaves the link out when the PDF object is gone" do
        File.delete(ActiveStorage::Blob.service.path_for(published_series.explainable.blob.key))

        get series_path(scholar, published_series)

        expect(response).to have_http_status(:ok)
        expect(html.at_css("article a[href*='/rails/active_storage/']")).to be_nil
      end
    end

    context "when the series has no PDF" do
      it "renders no PDF link" do
        get series_path(scholar, published_series)

        expect(response).to have_http_status(:ok)
        expect(html.at_css("article a[href*='/rails/active_storage/']")).to be_nil
      end
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
        expect(response).to be_not_found_page(I18n.t("messages.series_not_found"), back_to: series_index_path)
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
      expect(response).to be_not_found_page(I18n.t("messages.series_not_found"), back_to: series_index_path)
    end
  end
end
