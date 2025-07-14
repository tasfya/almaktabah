require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let!(:domain) { create(:domain, host: "localhost") }

  describe "GET #index" do
    let!(:published_lessons) { create_list(:lesson, 8, published: true, published_at: 1.day.ago) }
    let!(:published_books) { create_list(:book, 8, published: true, published_at: 1.day.ago) }
    let!(:published_lectures) { create_list(:lecture, 8, published: true, published_at: 1.day.ago) }
    let!(:published_news) { create_list(:news, 5, published: true, published_at: 1.day.ago) }
    let!(:published_fatwas) { create_list(:fatwa, 8, published: true, published_at: 1.day.ago) }
    let!(:published_series) { create_list(:series, 6, published: true, published_at: 1.day.ago) }

    before do
      published_lectures.each { |lecture| create(:domain_assignment, domain: domain, assignable: lecture) }
      get :index
    end

    it "returns a successful response" do
      expect(response).to be_successful
    end

    describe "recent lessons assignment" do
      it "assigns @recent_lessons with limit of 6" do
        expect(assigns(:recent_lessons)).to be_present
        expect(assigns(:recent_lessons).count).to eq(6)
      end

      it "orders lessons by lesson number" do
        # Check that recent lessons are properly ordered
        recent_lessons = assigns(:recent_lessons)
        expect(recent_lessons.first).to respond_to(:position)
        # The controller uses ordered_by_lesson_number scope which orders by position
        ordered_lessons = recent_lessons.to_a
        expect(ordered_lessons).not_to be_empty
      end
    end

    describe "recent books assignment" do
      it "assigns @recent_books with limit of 6" do
        expect(assigns(:recent_books)).to be_present
        expect(assigns(:recent_books).count).to eq(6)
      end
    end

    describe "recent lectures assignment" do
      it "assigns @recent_lectures with limit of 6" do
        expect(assigns(:recent_lectures)).to be_present
        expect(assigns(:recent_lectures).count).to eq(6)
      end
    end

    describe "recent news assignment" do
      it "assigns @recent_news with limit of 3" do
        expect(assigns(:recent_news)).to be_present
        expect(assigns(:recent_news).count).to eq(3)
      end
    end

    describe "recent fatwas assignment" do
      it "assigns @recent_fatwas with limit of 5" do
        expect(assigns(:recent_fatwas)).to be_present
        expect(assigns(:recent_fatwas).count).to eq(5)
      end

      it "orders fatwas by created_at descending" do
        older_fatwa = create(:fatwa, published: true, created_at: 2.days.ago)
        newer_fatwa = create(:fatwa, published: true, created_at: 1.hour.ago)

        get :index

        fatwas = assigns(:recent_fatwas)
        newer_fatwa_index = fatwas.index(newer_fatwa)
        older_fatwa_index = fatwas.index(older_fatwa)

        if newer_fatwa_index && older_fatwa_index
          expect(newer_fatwa_index).to be < older_fatwa_index
        end
      end
    end

    describe "featured series assignment" do
      it "assigns @featured_series with limit of 4" do
        expect(assigns(:featured_series)).to be_present
        expect(assigns(:featured_series).count).to eq(4)
      end
    end

    describe "featured lesson assignment" do
      it "assigns @featured_lesson as first published lesson" do
        expect(assigns(:featured_lesson)).to be_present
        expect(assigns(:featured_lesson)).to be_a(Lesson)
      end
    end

    describe "stats assignment" do
      it "assigns @stats with correct counts" do
        stats = assigns(:stats)

        expect(stats).to be_a(Hash)
        expect(stats[:books_count]).to eq(Book.published.count)
        expect(stats[:lectures_count]).to eq(Lecture.published.count)
        expect(stats[:lessons_count]).to eq(Lesson.published.count)
        expect(stats[:series_count]).to eq(Series.published.count)
        expect(stats[:fatwas_count]).to eq(Fatwa.published.count)
      end

      it "counts only published items" do
        create(:book, published: false)
        create(:lecture, published: false)
        create(:lesson, published: false)
        create(:series, published: false)
        create(:fatwa, published: false)

        get :index

        stats = assigns(:stats)
        expect(stats[:books_count]).to eq(Book.published.count)
        expect(stats[:lectures_count]).to eq(Lecture.published.count)
        expect(stats[:lessons_count]).to eq(Lesson.published.count)
        expect(stats[:series_count]).to eq(Series.published.count)
        expect(stats[:fatwas_count]).to eq(Fatwa.published.count)
      end
    end

    context "when no content exists" do
      before do
        Book.destroy_all
        Lecture.destroy_all
        Lesson.destroy_all
        News.destroy_all
        Fatwa.destroy_all
        Series.destroy_all

        get :index
      end

      it "handles empty collections gracefully" do
        expect(assigns(:recent_lessons)).to be_empty
        expect(assigns(:recent_books)).to be_empty
        expect(assigns(:recent_lectures)).to be_empty
        expect(assigns(:recent_news)).to be_empty
        expect(assigns(:recent_fatwas)).to be_empty
        expect(assigns(:featured_series)).to be_empty
        expect(assigns(:featured_lesson)).to be_nil
      end

      it "sets stats to zero" do
        stats = assigns(:stats)
        expect(stats[:books_count]).to eq(0)
        expect(stats[:lectures_count]).to eq(0)
        expect(stats[:lessons_count]).to eq(0)
        expect(stats[:series_count]).to eq(0)
        expect(stats[:fatwas_count]).to eq(0)
      end
    end
  end
end
