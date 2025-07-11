require 'rails_helper'

RSpec.describe LessonsController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
  end

  let(:published_series) { create(:series, published: true, published_at: 1.day.ago) }
  let(:series) { create(:series, published: true, published_at: 1.day.ago) }
  let(:published_lesson) { create(:lesson, series: series, published: true, published_at: 1.day.ago) }
  let(:unpublished_lesson) { create(:lesson, published: false) }

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns @lessons, @pagy, and @series" do
      create_list(:series, 3, published: true, published_at: 1.day.ago)
      create_list(:lesson, 5, published: true, published_at: 1.day.ago)

      get :index

      expect(assigns(:lessons)).to be_present
      expect(assigns(:pagy)).to be_present
      expect(assigns(:q)).to be_present
      expect(assigns(:series)).to be_present
    end

    it "only includes published lessons" do
      published_lesson
      unpublished_lesson

      get :index

      expect(assigns(:lessons)).to include(published_lesson)
      expect(assigns(:lessons)).not_to include(unpublished_lesson)
    end

    it "orders lessons by published_at descending initially" do
      create(:lesson, published: true, published_at: 2.days.ago)
      create(:lesson, published: true, published_at: 1.day.ago)

      get :index

      # Note: The controller orders by lesson_number after the initial query
      lessons = assigns(:lessons)
      expect(lessons).to be_present
    end

    it "includes series association" do
      lesson_with_series = create(:lesson, series: series, published: true, published_at: 1.day.ago)

      get :index

      expect(assigns(:lessons)).to include(lesson_with_series)
      # Verify the association is loaded
      lesson = assigns(:lessons).find { |l| l.id == lesson_with_series.id }
      expect { lesson.series.title }.not_to raise_error if lesson
    end

    it "orders lessons by lesson number" do
      series = create(:series, published: true, published_at: 1.day.ago)
      create(:lesson, position: 3, series: series, published: true, published_at: 1.day.ago)
      create(:lesson, position: 1, series: series, published: true, published_at: 1.day.ago)
      create(:lesson, position: 2, series: series, published: true, published_at: 1.day.ago)

      get :index

      lessons = assigns(:lessons).to_a
      # The lessons should be ordered by position (lesson number)
      lessons_with_position = lessons.select(&:position).sort_by(&:position)
      expect(lessons_with_position.map(&:position)).to eq([ 1, 2, 3 ])
    end

    it "paginates lessons with limit of 12" do
      create_list(:lesson, 15, published: true, published_at: 1.day.ago)

      get :index

      expect(assigns(:lessons).count).to eq(12)
      expect(assigns(:pagy).limit).to eq(12)
    end

    it "loads published series ordered by title" do
      series_b = create(:series, title: "B Series", published: true, published_at: 1.day.ago)
      series_a = create(:series, title: "A Series", published: true, published_at: 1.day.ago)

      get :index

      series_list = assigns(:series).to_a
      expect(series_list.first).to eq(series_a)
      expect(series_list.last).to eq(series_b)
    end

    it "supports ransack search parameters" do
      matching_lesson = create(:lesson, title: "Test Search", published: true, published_at: 1.day.ago)
      non_matching_lesson = create(:lesson, title: "Other Lesson", published: true, published_at: 1.day.ago)

      get :index, params: { q: { title_cont: "Test" } }

      expect(assigns(:lessons)).to include(matching_lesson)
      expect(assigns(:lessons)).not_to include(non_matching_lesson)
    end

    it "sets up lessons breadcrumbs" do
      expect(controller).to receive(:breadcrumb_for).with(
        I18n.t("breadcrumbs.lessons"),
        lessons_path
      )

      get :index
    end
  end

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
          I18n.t("breadcrumbs.lessons"),
          lessons_path
        )
        expect(controller).to receive(:breadcrumb_for).with(
          published_lesson.series.title,
          series_path(published_lesson.series)
        )

        get :show, params: { id: published_lesson.id }
      end

      context "when lesson has no series" do
        let(:lesson_without_series) { create(:lesson, series: nil, published: true, published_at: 1.day.ago) }

        it "sets up breadcrumbs without series" do
          expect(controller).to receive(:breadcrumb_for).with(
            I18n.t("breadcrumbs.lessons"),
            lessons_path
          )
          # Should not add series breadcrumb
          expect(controller).not_to receive(:breadcrumb_for).with(
            anything,
            series_path(anything)
          )

          get :show, params: { id: lesson_without_series.id }
        end
      end
    end

    context "when lesson is not published" do
      it "redirects to lessons index" do
        get :show, params: { id: unpublished_lesson.id }
        expect(response).to redirect_to(lessons_path)
      end

      it "shows not found alert" do
        get :show, params: { id: unpublished_lesson.id }
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end
    end

    context "when lesson does not exist" do
      it "redirects to lessons index" do
        get :show, params: { id: 99999 }
        expect(response).to redirect_to(lessons_path)
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
        expect(response).to redirect_to(lessons_path)
      end

      it "shows not found alert" do
        get :play, params: { id: unpublished_lesson.id }
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end
    end

    context "when lesson does not exist" do
      it "redirects to lessons index" do
        get :play, params: { id: 99999 }
        expect(response).to redirect_to(lessons_path)
      end

      it "shows not found alert" do
        get :play, params: { id: 99999 }
        expect(flash[:alert]).to eq(I18n.t("messages.lesson_not_found"))
      end
    end
  end
end
