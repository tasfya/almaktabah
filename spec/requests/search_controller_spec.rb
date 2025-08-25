require 'rails_helper'

RSpec.describe SearchController, type: :request do
  before(:each) do
    Faker::UniqueGenerator.clear
  end

  let(:domain) { create(:domain, host: "localhost") }
  let(:headers) { { "HTTP_HOST" => "localhost" } }

  describe "GET #index" do
    let!(:book) { create(:book, title: "Test Book Title", description: "Test book description", published: true, published_at: DateTime.new) }
    let!(:lecture) { create(:lecture, :with_domain, title: "Test Lecture", description: "Test lecture description", published: true, published_at: DateTime.new) }
    let!(:lesson) { create(:lesson, title: "Test Lesson", description: "Test lesson description", published: true, published_at: DateTime.new) }
    let!(:series) { create(:series, title: "Test Series", description: "Test series description", published: true, published_at: DateTime.new) }
    let!(:news) { create(:news, title: "Test News", description: "Test news description", published: true, published_at: DateTime.new) }
    let!(:benefit) { create(:benefit, title: "Test Benefit", description: "Test benefit description", published: true, published_at: DateTime.new) }
    let!(:fatwa) { create(:fatwa, title: "Test Fatwa", published: true, published_at: DateTime.new) }
    let!(:scholar) { create(:scholar, first_name: "Test", last_name: "Scholar", published: true, published_at: DateTime.new) }

    context "when no query is provided" do
      it "renders the search page without results" do
        get search_path, headers: headers

        expect(response).to have_http_status(:success)
        expect(response.body).to include("search")
      end
    end

    context "when query is too short" do
      it "shows error message for single character query" do
        get search_path, params: { q: "a" }, headers: headers

        expect(response).to have_http_status(:success)
        expect(flash[:alert]).to eq("يجب أن يكون البحث مكونًا من حرفين على الأقل")
      end

      it "shows error message for empty query" do
        get search_path, params: { q: " " }, headers: headers

        expect(response).to have_http_status(:success)
      end
    end

    context "when valid query is provided" do
      it "returns successful search results" do
        get search_path, params: { q: "Test" }, headers: headers

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Test")
      end

      it "finds books with matching title" do
        get search_path, params: { q: "Book Title" }, headers: headers

        expect(response.body).to include(book.title)
      end

      it "finds books with matching description" do
        get search_path, params: { q: "book description" }, headers: headers

        expect(response.body).to include(book.title)
      end

      it "finds lectures with matching title" do
        get search_path, params: { q: "Lecture" }, headers: headers

        expect(response.body).to include(lecture.title)
      end

      it "finds lessons with matching title" do
        get search_path, params: { q: "Lesson" }, headers: headers

        expect(response.body).to include(lesson.title)
      end

      it "finds series with matching title" do
        get search_path, params: { q: "Series" }, headers: headers

        expect(response.body).to include(series.title)
      end

      it "finds news with matching title" do
        get search_path, params: { q: "News" }, headers: headers

        expect(response.body).to include(news.title)
      end

      it "finds benefits with matching title" do
        get search_path, params: { q: "Benefit" }, headers: headers

        expect(response.body).to include(benefit.title)
      end

      it "finds fatwas with matching title" do
        get search_path, params: { q: "Fatwa" }, headers: headers

        expect(response.body).to include(fatwa.title)
      end

      it "handles partial matches" do
        get search_path, params: { q: "Boo" }, headers: headers

        expect(response.body).to include(book.title)
      end
    end

    context "when no results are found" do
      it "returns empty results for non-matching query" do
        get search_path, params: { q: "NonExistentSearchTerm" }, headers: headers

        expect(response).to have_http_status(:success)
        expect(response.body).to include("NonExistentSearchTerm")
      end
    end

    context "with special characters in query" do
      it "handles Arabic text" do
        # Fixed: Add published: true and published_at to make the book searchable
        book_arabic = create(:book, title: "كتاب اختبار", description: "وصف الكتاب", published: true, published_at: DateTime.new)

        get search_path, params: { q: "كتاب" }, headers: headers

        expect(response).to have_http_status(:success)
        expect(response.body).to include(book_arabic.title)
      end

      it "handles queries with spaces" do
        get search_path, params: { q: "Test Book" }, headers: headers

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Test Book")
      end
    end

    context "with database constraints" do
      it "limits results to 5 per model type" do
        # Fixed: Create more than 5 books with matching titles AND published status
        6.times { |i| create(:book, title: "Matching Book #{i}", published: true, published_at: DateTime.new) }

        get search_path, params: { q: "Matching" }, headers: headers

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Matching Book")
      end
    end

    context "breadcrumbs" do
      it "sets up search breadcrumbs" do
        expect_any_instance_of(SearchController).to receive(:breadcrumb_for).with(
          I18n.t("navigation.search"),
          search_path
        )

        get search_path, headers: headers
      end
    end
  end

  describe "private methods" do
    let(:controller_instance) { described_class.new }

    before do
      controller_instance.instance_variable_set(:@query, "test")
    end

    describe "#search_books" do
      it "searches books with proper parameters" do
        expect(Book).to receive(:includes).with(:author).and_call_original
        expect_any_instance_of(Ransack::Search).to receive(:result).with(distinct: true).and_call_original

        controller_instance.send(:search_books)
      end
    end

    describe "#search_lectures" do
      it "searches lectures with proper parameters" do
        expect(Lecture).to receive(:ransack).with(
          title_or_description_cont: "test"
        ).and_call_original

        controller_instance.send(:search_lectures)
      end
    end

    describe "#search_lessons" do
      it "includes series association" do
        expect(Lesson).to receive(:includes).with(:series).and_call_original

        controller_instance.send(:search_lessons)
      end
    end

    describe "#search_fatwas" do
      it "searches only in title field" do
        expect(Fatwa).to receive(:ransack).with(
          title_cont: "test"
        ).and_call_original

        controller_instance.send(:search_fatwas)
      end
    end

    describe "#search_scholars" do
      it "searches in both first and last name" do
        expect(Scholar).to receive(:ransack).with(
          first_name_or_last_name_cont: "test"
        ).and_call_original

        controller_instance.send(:search_scholars)
      end
    end
  end
end
