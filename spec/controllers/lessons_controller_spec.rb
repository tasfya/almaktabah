# frozen_string_literal: true

require "rails_helper"

RSpec.describe LessonsController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }
  let!(:series) { create(:series, scholar: scholar, published: true, published_at: 1.day.ago) }
  let!(:published_lesson) { create(:lesson, series: series, published: true, published_at: 1.day.ago) }
  let!(:unpublished_lesson) { create(:lesson, series: series, published: false) }

  before do
    allow(controller).to receive(:set_domain)
    controller.instance_variable_set(:@domain, domain)

    create(:domain_assignment, domain: domain, assignable: series)
    create(:domain_assignment, domain: domain, assignable: published_lesson)
    create(:domain_assignment, domain: domain, assignable: unpublished_lesson)
  end

  describe "GET #show" do
    context "when lesson is published" do
      let!(:other_lesson) { create(:lesson, series: series, published: true, published_at: 2.days.ago) }

      before do
        create(:domain_assignment, domain: domain, assignable: other_lesson)
      end

      it "shows the lesson" do
        get :show, params: { scholar_id: scholar.to_param, series_id: series.to_param, id: published_lesson.id }
        expect(response).to be_successful
        expect(assigns(:lesson)).to eq(published_lesson)
      end

      it "assigns related lessons from the same series" do
        get :show, params: { scholar_id: scholar.to_param, series_id: series.to_param, id: published_lesson.id }
        related = assigns(:related_lessons)
        expect(related).to include(other_lesson)
        expect(related).not_to include(published_lesson)
      end

      it "limits related lessons to 4" do
        create_list(:lesson, 6, series: series, published: true, published_at: 1.day.ago) do |l|
          create(:domain_assignment, domain: domain, assignable: l)
        end

        get :show, params: { scholar_id: scholar.to_param, series_id: series.to_param, id: published_lesson.id }
        expect(assigns(:related_lessons).count).to eq(4)
      end

      it "sets up breadcrumbs" do
        expect(controller).to receive(:breadcrumb_for).with(I18n.t("breadcrumbs.series"), series_index_path)
        expect(controller).to receive(:breadcrumb_for).with(series.title, series_path(series, scholar_id: scholar.slug))
        expect(controller).to receive(:breadcrumb_for).with(
          published_lesson.title,
          series_lesson_path(scholar, series, published_lesson)
        )
        get :show, params: { scholar_id: scholar.to_param, series_id: series.to_param, id: published_lesson.id }
      end
    end

    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = scholar.slug
        scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get :show, params: { scholar_id: old_slug, series_id: series.to_param, id: published_lesson.id }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(series_lesson_path(scholar, series, published_lesson))
      end
    end

    context "when lesson is unpublished or not found" do
      it "redirects for unpublished lesson" do
        get :show, params: { scholar_id: scholar.to_param, series_id: series.to_param, id: unpublished_lesson.id }
        expect(response).to redirect_to(series_index_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end

      it "redirects for missing lesson" do
        get :show, params: { scholar_id: scholar.to_param, series_id: series.to_param, id: 999999 }
        expect(response).to redirect_to(series_index_path)
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end
    end
  end

  describe "GET #legacy_index_redirect" do
    it "redirects to series index with 301" do
      get :legacy_index_redirect
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(series_index_path)
    end
  end

  describe "GET #legacy_redirect" do
    it "redirects to nested lesson URL with 301" do
      get :legacy_redirect, params: { id: published_lesson.id }
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(series_lesson_path(scholar, series, published_lesson))
    end

    it "redirects to series index when lesson not found" do
      get :legacy_redirect, params: { id: 999999 }
      expect(response).to redirect_to(series_index_path)
      expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
    end
  end
end
