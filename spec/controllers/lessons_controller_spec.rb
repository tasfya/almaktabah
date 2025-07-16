require 'rails_helper'

RSpec.describe LessonsController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end
  let(:domain) { create(:domain, host: "localhost") }
  let(:published_series) { create(:series, published: true, published_at: 1.day.ago) }
  let(:series) { create(:series, published: true, published_at: 1.day.ago) }
  let(:published_lesson) { create(:lesson, series: series, published: true, published_at: 1.day.ago) }
  let(:unpublished_lesson) { create(:lesson, published: false) }

  describe "GET #show" do
    context "when lesson is published" do
      let!(:same_series_lesson) { create(:lesson, series: published_lesson.series, published: true, published_at: 1.day.ago) }
      let!(:different_series_lesson) { create(:lesson, published: true, published_at: 1.day.ago) }

      it "returns a successful response" do
        get :show, params: { id: published_lesson.id }
        expect(response).to be_successful
      end

      it "assigns the requested lesson" do
        get :show, params: { id: published_lesson.id }
        expect(assigns(:lesson)).to eq(published_lesson)
      end

      it "assigns related lessons from same series" do
        get :show, params: { id: published_lesson.id }

        related_lessons = assigns(:related_lessons)
        expect(related_lessons).to include(same_series_lesson)
        expect(related_lessons).not_to include(different_series_lesson)
        expect(related_lessons).not_to include(published_lesson)
      end

      it "limits related lessons to 4" do
        create_list(:lesson, 6, series: published_lesson.series, published: true, published_at: 1.day.ago)

        get :show, params: { id: published_lesson.id }

        expect(assigns(:related_lessons).count).to eq(4)
      end

      it "sets up show breadcrumbs with series" do
        expect(controller).to receive(:breadcrumb_for).with(
          I18n.t("breadcrumbs.series"),
          series_index_path
        )
        expect(controller).to receive(:breadcrumb_for).with(
          published_lesson.series.title,
          series_index_path(published_lesson.series)
        )

        get :show, params: { id: published_lesson.id }
      end

      context "when lesson has no series" do
        let(:lesson_without_series) { create(:lesson, series: nil, published: true, published_at: 1.day.ago) }

        it "sets up breadcrumbs without series" do
          expect(controller).to receive(:breadcrumb_for).with(
            I18n.t("breadcrumbs.series"),
            series_index_path
          )
          # Should not add series breadcrumb
          expect(controller).not_to receive(:breadcrumb_for).with(
            anything,
            series_index_path(anything)
          )

          get :show, params: { id: lesson_without_series.id }
        end
      end
    end

    context "when lesson is not published" do
      it "redirects to lessons index" do
        get :show, params: { id: unpublished_lesson.id }
        expect(response).to redirect_to(series_index_path)
      end

      it "shows not found alert" do
        get :show, params: { id: unpublished_lesson.id }
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end
    end

    context "when lesson does not exist" do
      it "redirects to lessons index" do
        get :show, params: { id: 99999 }
        expect(response).to redirect_to(series_index_path)
      end

      it "shows not found alert" do
        get :show, params: { id: 99999 }
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end
    end
  end

  describe "GET #play" do
    context "when lesson is published" do
      it "returns a successful response" do
        get :play, params: { id: published_lesson.id }
        expect(response).to be_successful
      end

      it "assigns the requested lesson" do
        get :play, params: { id: published_lesson.id }
        expect(assigns(:lesson)).to eq(published_lesson)
      end
    end

    context "when lesson is not published" do
      it "redirects to lessons index" do
        get :play, params: { id: unpublished_lesson.id }
        expect(response).to redirect_to(series_index_path)
      end

      it "shows not found alert" do
        get :play, params: { id: unpublished_lesson.id }
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end
    end

    context "when lesson does not exist" do
      it "redirects to lessons index" do
        get :play, params: { id: 99999 }
        expect(response).to redirect_to(series_index_path)
      end

      it "shows not found alert" do
        get :play, params: { id: 99999 }
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end
    end
  end
end
