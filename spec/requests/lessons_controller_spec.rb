require 'rails_helper'

RSpec.describe LessonsController, type: :request  do
  before do
    @domain = create(:domain, host: "www.example.com")
    @headers = { "HTTP" => @domain.host }
  end
  before(:each) do
    Faker::UniqueGenerator.clear
  end
  let(:published_series) { create(:series, published: true, published_at: 1.day.ago) }
  let(:series) { create(:series, published: true, published_at: 1.day.ago) }
  let(:published_lesson) { create(:lesson, series: series, published: true, published_at: 1.day.ago) }
  let(:unpublished_lesson) { create(:lesson, published: false) }

  xdescribe "GET #show" do
    context "when lesson is published" do
      let!(:same_series_lesson) { create(:lesson, series: published_lesson.series, published: true, published_at: 1.day.ago) }
      let!(:different_series_lesson) { create(:lesson, published: true, published_at: 1.day.ago) }

      it "returns a successful response" do
        published_lesson.assign_to(@domain)
        get lesson_path(published_lesson.id), headers: @headers
        expect(response).to be_successful
      end

      it "assigns the requested lesson" do
        published_lesson.assign_to(@domain)
        get lesson_path(published_lesson.id), headers: @headers
        expect(assigns(:lesson)).to eq(published_lesson)
      end

      it "assigns related lessons from same series" do
        published_lesson.assign_to(@domain)
        expect(assigns(:lesson)).to eq(published_lesson)
        get lesson_path(published_lesson.id), headers: @headers

        related_lessons = assigns(:related_lessons)
        expect(related_lessons).to include(same_series_lesson)
        expect(related_lessons).not_to include(different_series_lesson)
        expect(related_lessons).not_to include(published_lesson)
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
        published_lesson.assign_to(@domain)
        get lesson_path(published_lesson.id), headers: @headers
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
          lesson_without_series.assign_to(@domain)
          get lesson_path(lesson_without_series.id), headers: @headers
        end
      end
    end

    context "when lesson is not published" do
      it "redirects to lessons index" do
        get lesson_path(unpublished_lesson.id), headers: @headers
        expect(response).to redirect_to(series_index_path)
      end

      it "shows not found alert" do
        get lesson_path(unpublished_lesson), headers: @headers
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end
    end

    context "when lesson does not exist" do
      it "redirects to lessons index" do
        get lesson_path(99999), headers: @headers
        expect(response).to redirect_to(series_index_path)
      end

      it "shows not found alert" do
        get lesson_path(99999), headers: @headers
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end
    end
  end
end
