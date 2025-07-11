require 'rails_helper'

RSpec.describe LecturesController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
  end

  let(:published_lecture) { create(:lecture, published: true, published_at: 1.day.ago) }
  let(:unpublished_lecture) { create(:lecture, published: false) }

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns @lectures and @pagy" do
      create_list(:lecture, 5, published: true, published_at: 1.day.ago)

      get :index

      expect(assigns(:lectures)).to be_present
      expect(assigns(:pagy)).to be_present
      expect(assigns(:q)).to be_present
    end

    it "only includes published lectures" do
      published_lecture
      unpublished_lecture

      get :index

      expect(assigns(:lectures)).to include(published_lecture)
      expect(assigns(:lectures)).not_to include(unpublished_lecture)
    end

    it "orders lectures by published_at descending" do
      older_lecture = create(:lecture, published: true, published_at: 2.days.ago)
      newer_lecture = create(:lecture, published: true, published_at: 1.day.ago)

      get :index

      lectures = assigns(:lectures)
      expect(lectures.first).to eq(newer_lecture)
      expect(lectures.last).to eq(older_lecture)
    end

    it "paginates lectures with limit of 12" do
      create_list(:lecture, 15, published: true, published_at: 1.day.ago)

      get :index

      expect(assigns(:lectures).count).to eq(12)
      expect(assigns(:pagy).limit).to eq(12)
    end

    it "supports ransack search parameters" do
      matching_lecture = create(:lecture, title: "Test Search", published: true, published_at: 1.day.ago)
      non_matching_lecture = create(:lecture, title: "Other Lecture", published: true, published_at: 1.day.ago)

      get :index, params: { q: { title_cont: "Test" } }

      expect(assigns(:lectures)).to include(matching_lecture)
      expect(assigns(:lectures)).not_to include(non_matching_lecture)
    end

    it "sets up lectures breadcrumbs" do
      expect(controller).to receive(:breadcrumb_for).with(
        I18n.t("breadcrumbs.lectures"),
        lectures_path
      )

      get :index
    end
  end

  describe "GET #show" do
    context "when lecture is published" do
      let!(:same_category_lecture) { create(:lecture, category: published_lecture.category, published: true, published_at: 1.day.ago) }
      let!(:different_category_lecture) { create(:lecture, category: "Different", published: true, published_at: 1.day.ago) }

      it "returns a successful response" do
        get :show, params: { id: published_lecture.id }
        expect(response).to be_successful
      end

      it "assigns the requested lecture" do
        get :show, params: { id: published_lecture.id }
        expect(assigns(:lecture)).to eq(published_lecture)
      end

      it "assigns related lectures from same category" do
        get :show, params: { id: published_lecture.id }

        related_lectures = assigns(:related_lectures)
        expect(related_lectures).to include(same_category_lecture)
        expect(related_lectures).not_to include(different_category_lecture)
        expect(related_lectures).not_to include(published_lecture)
      end

      it "limits related lectures to 4" do
        create_list(:lecture, 6, category: published_lecture.category, published: true, published_at: 1.day.ago)

        get :show, params: { id: published_lecture.id }

        expect(assigns(:related_lectures).count).to eq(4)
      end

      it "sets up show breadcrumbs" do
        expect(controller).to receive(:breadcrumb_for).with(
          I18n.t("breadcrumbs.lectures"),
          lectures_path
        )
        expect(controller).to receive(:breadcrumb_for).with(
          published_lecture.title,
          lecture_path(published_lecture)
        )

        get :show, params: { id: published_lecture.id }
      end
    end

    context "when lecture is not published" do
      it "redirects to lectures index" do
        get :show, params: { id: unpublished_lecture.id }
        expect(response).to redirect_to(lectures_path)
      end

      it "shows not found alert" do
        get :show, params: { id: unpublished_lecture.id }
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end

    context "when lecture does not exist" do
      it "redirects to lectures index" do
        get :show, params: { id: 99999 }
        expect(response).to redirect_to(lectures_path)
      end

      it "shows not found alert" do
        get :show, params: { id: 99999 }
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end
  end

  describe "GET #play" do
    context "when lecture is published" do
      it "returns a successful response" do
        get :play, params: { id: published_lecture.id }
        expect(response).to be_successful
      end

      it "assigns the requested lecture" do
        get :play, params: { id: published_lecture.id }
        expect(assigns(:lecture)).to eq(published_lecture)
      end
    end

    context "when lecture is not published" do
      it "redirects to lectures index" do
        get :play, params: { id: unpublished_lecture.id }
        expect(response).to redirect_to(lectures_path)
      end

      it "shows not found alert" do
        get :play, params: { id: unpublished_lecture.id }
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end

    context "when lecture does not exist" do
      it "redirects to lectures index" do
        get :play, params: { id: 99999 }
        expect(response).to redirect_to(lectures_path)
      end

      it "shows not found alert" do
        get :play, params: { id: 99999 }
        expect(flash[:alert]).to eq(I18n.t("messages.lecture_not_found"))
      end
    end
  end
end
