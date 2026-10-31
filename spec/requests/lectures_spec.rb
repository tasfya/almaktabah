# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Lectures", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }
  let!(:published_lecture) { create(:lecture, published: true, published_at: 1.day.ago, scholar: scholar) }
  let!(:unpublished_lecture) { create(:lecture, published: false, scholar: scholar) }

  before do
    host! "localhost"
    create(:domain_assignment, domain: domain, assignable: published_lecture)
    create(:domain_assignment, domain: domain, assignable: unpublished_lecture)
  end

  def lecture_url_for(lecture)
    lecture_path(scholar, lecture, kind: lecture.kind_for_url)
  end

  describe "GET /lectures" do
    let(:collection_search) { instance_double(TypesenseSearch::CollectionSearchService, call: empty_search_result) }

    before { allow(TypesenseSearch::CollectionSearchService).to receive(:new).and_return(collection_search) }

    it "searches the lecture collection on the request's domain, 15 per page by default" do
      get lectures_path

      expect(TypesenseSearch::CollectionSearchService).to have_received(:new).with(
        collection: "lecture", query: nil, domain_id: domain.id, scholars: nil, page: nil, per_page: 15
      )
    end

    it "passes the query, scholar filter and paging params through" do
      get lectures_path, params: { q: " tawhid ", scholars: [ "Scholar A" ], page: "3", per_page: "9" }

      expect(TypesenseSearch::CollectionSearchService).to have_received(:new).with(
        collection: "lecture", query: "tawhid", domain_id: domain.id, scholars: [ "Scholar A" ], page: "3", per_page: 9
      )
    end

    it "renders the search page" do
      get lectures_path
      expect(response).to have_http_status(:ok)
      expect(search_page_rendered?).to be(true)
    end

    it "shows the lectures breadcrumb" do
      get lectures_path
      expect(breadcrumb_trail).to eq([ [ I18n.t("breadcrumbs.lectures"), nil ] ])
    end
  end

  describe "GET /:scholar_id/:kind/:id" do
    context "when lecture is published" do
      let!(:same_category) { create(:lecture, category: published_lecture.category, published: true, scholar: scholar) }
      let!(:other_category) { create(:lecture, category: "Other", published: true, scholar: scholar) }

      before do
        [ same_category, other_category ].each do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end
      end

      it "shows the lecture" do
        get lecture_url_for(published_lecture)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(ERB::Util.html_escape(published_lecture.title))
      end

      # The show view does not render related lectures, so the query is only
      # observable through the assigned instance variable.
      it "assigns related lectures from the same category" do
        get lecture_url_for(published_lecture)
        expect(assigns(:related_lectures)).to include(same_category)
        expect(assigns(:related_lectures)).not_to include(published_lecture, other_category)
      end

      it "limits related lectures to 4" do
        create_list(:lecture, 6, category: published_lecture.category, published: true, scholar: scholar) do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end

        get lecture_url_for(published_lecture)
        expect(assigns(:related_lectures).count).to eq(4)
      end

      it "shows the lectures index and lecture breadcrumbs" do
        get lecture_url_for(published_lecture)
        expect(breadcrumb_trail).to eq([
          [ I18n.t("breadcrumbs.lectures"), lectures_path ],
          [ published_lecture.title, nil ]
        ])
      end
    end

    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = scholar.slug
        scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get lecture_path(old_slug, published_lecture.to_param, kind: published_lecture.kind_for_url)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(lecture_url_for(published_lecture))
      end
    end

    context "when accessed via old lecture slug" do
      it "redirects to canonical URL with 301" do
        old_slug = published_lecture.slug
        published_lecture.update!(title: "New Unique Lecture Title #{SecureRandom.hex(4)}")

        get lecture_path(scholar.to_param, old_slug, kind: published_lecture.kind_for_url)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(lecture_url_for(published_lecture))
      end
    end

    context "when lecture is unpublished or not found" do
      it "redirects and shows alert for unpublished lecture" do
        get lecture_path(scholar.id, unpublished_lecture.id, kind: unpublished_lecture.kind_for_url)
        expect(response).to be_not_found_page(I18n.t("messages.lecture_not_found"), back_to: lectures_path)
      end

      it "redirects and shows alert for missing lecture" do
        get lecture_path(scholar.id, 999999, kind: I18n.t("activerecord.attributes.lecture.kind.sermon"))
        expect(response).to be_not_found_page(I18n.t("messages.lecture_not_found"), back_to: lectures_path)
      end
    end
  end

  describe "GET /lectures/:id (legacy)" do
    it "redirects to new lecture URL with 301" do
      get "/lectures/#{published_lecture.id}"
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(lecture_path(scholar.slug, published_lecture, kind: published_lecture.kind_for_url))
    end

    it "redirects to lectures index when not found" do
      get "/lectures/999999"
      expect(response).to be_not_found_page(I18n.t("messages.lecture_not_found"), back_to: lectures_path)
    end
  end
end
