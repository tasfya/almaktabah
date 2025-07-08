require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  describe "GET #index" do
    let!(:book) { create(:book, title: "Test Book Title", description: "Test book description") }
    let!(:lecture) { create(:lecture, title: "Test Lecture", description: "Test lecture description") }
    let!(:lesson) { create(:lesson, title: "Test Lesson", description: "Test lesson description") }
    let!(:series) { create(:series, title: "Test Series", description: "Test series description") }
    let!(:news) { create(:news, title: "Test News", description: "Test news description") }
    let!(:benefit) { create(:benefit, title: "Test Benefit", description: "Test benefit description") }
    let!(:fatwa) { create(:fatwa, title: "Test Fatwa") }
    let!(:scholar) { create(:scholar, first_name: "Test", last_name: "Scholar") }

    context "when no query is provided" do
      it "renders the search page without results" do
        get :index

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to be_nil
        expect(assigns(:results)).to eq({})
        expect(assigns(:total_results)).to eq(0)
      end
    end

    context "when query is too short" do
      it "shows error message for single character query" do
        get :index, params: { q: "a" }

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to eq("a")
        expect(flash[:alert]).to eq("يجب أن يكون البحث مكونًا من حرفين على الأقل")
        expect(assigns(:results)).to eq({})
        expect(assigns(:total_results)).to eq(0)
      end

      it "shows error message for empty query" do
        get :index, params: { q: " " }

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to eq("")
        expect(assigns(:results)).to eq({})
        expect(assigns(:total_results)).to eq(0)
      end
    end

    context "when valid query is provided" do
      it "searches across all models and returns results" do
        get :index, params: { q: "Test" }

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to eq("Test")
        expect(assigns(:results)).to be_a(Hash)
        expect(assigns(:total_results)).to be > 0

        # Check that all model types are searched
        expect(assigns(:results)).to have_key(:books)
        expect(assigns(:results)).to have_key(:lectures)
        expect(assigns(:results)).to have_key(:lessons)
        expect(assigns(:results)).to have_key(:series)
        expect(assigns(:results)).to have_key(:news)
        expect(assigns(:results)).to have_key(:benefits)
        expect(assigns(:results)).to have_key(:fatwas)
        expect(assigns(:results)).to have_key(:scholars)
      end

      it "finds books with matching title" do
        get :index, params: { q: "Book Title" }

        expect(assigns(:results)[:books]).to include(book)
        expect(assigns(:total_results)).to be >= 1
      end

      it "finds books with matching description" do
        get :index, params: { q: "book description" }

        expect(assigns(:results)[:books]).to include(book)
      end

      it "finds lectures with matching title" do
        get :index, params: { q: "Lecture" }

        expect(assigns(:results)[:lectures]).to include(lecture)
      end

      it "finds lessons with matching title" do
        get :index, params: { q: "Lesson" }

        expect(assigns(:results)[:lessons]).to include(lesson)
      end

      it "finds series with matching title" do
        get :index, params: { q: "Series" }

        expect(assigns(:results)[:series]).to include(series)
      end

      it "finds news with matching title" do
        get :index, params: { q: "News" }

        expect(assigns(:results)[:news]).to include(news)
      end

      it "finds benefits with matching title" do
        get :index, params: { q: "Benefit" }

        expect(assigns(:results)[:benefits]).to include(benefit)
      end

      it "finds fatwas with matching title" do
        get :index, params: { q: "Fatwa" }

        expect(assigns(:results)[:fatwas]).to include(fatwa)
      end

      it "finds scholars with matching first name" do
        get :index, params: { q: "Test" }

        expect(assigns(:results)[:scholars]).to include(scholar)
      end

      it "finds scholars with matching last name" do
        get :index, params: { q: "Scholar" }

        expect(assigns(:results)[:scholars]).to include(scholar)
      end

      it "is case insensitive" do
        get :index, params: { q: "test" }

        expect(assigns(:results)[:books]).to include(book)
        expect(assigns(:results)[:lectures]).to include(lecture)
      end

      it "handles partial matches" do
        get :index, params: { q: "Boo" }

        expect(assigns(:results)[:books]).to include(book)
      end

      it "calculates total results correctly" do
        get :index, params: { q: "Test" }

        total = assigns(:results).values.map(&:count).sum
        expect(assigns(:total_results)).to eq(total)
      end
    end

    context "when no results are found" do
      it "returns empty results for non-matching query" do
        get :index, params: { q: "NonExistentSearchTerm" }

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to eq("NonExistentSearchTerm")
        expect(assigns(:total_results)).to eq(0)

        assigns(:results).values.each do |results|
          expect(results).to be_empty
        end
      end
    end

    context "with special characters in query" do
      it "handles Arabic text" do
        book_arabic = create(:book, title: "كتاب اختبار", description: "وصف الكتاب")

        get :index, params: { q: "كتاب" }

        expect(response).to have_http_status(:success)
        expect(assigns(:results)[:books]).to include(book_arabic)
      end

      it "handles queries with spaces" do
        get :index, params: { q: "Test Book" }

        expect(response).to have_http_status(:success)
        expect(assigns(:query)).to eq("Test Book")
      end

      it "strips whitespace from query" do
        get :index, params: { q: "  Test  " }

        expect(assigns(:query)).to eq("Test")
      end
    end

    context "with database constraints" do
      it "limits results to 5 per model type" do
        # Create more than 5 books with matching titles
        6.times { |i| create(:book, title: "Matching Book #{i}") }

        get :index, params: { q: "Matching" }

        expect(assigns(:results)[:books].count).to eq(5)
      end

      it "includes proper associations" do
        get :index, params: { q: "Test" }

        # Check that books include author association
        book_result = assigns(:results)[:books].first
        expect { book_result.author.name }.not_to raise_error

        # Check that lessons include series association
        lesson_result = assigns(:results)[:lessons].first
        expect { lesson_result.series.title }.not_to raise_error
      end
    end

    context "ordering and sorting" do
      let!(:old_book) { create(:book, title: "Old Test Book", published_date: 1.year.ago) }
      let!(:new_book) { create(:book, title: "New Test Book", published_date: 1.day.ago) }

      it "orders books by published date (recent first)" do
        get :index, params: { q: "Test Book" }

        books = assigns(:results)[:books]
        expect(books.first).to eq(new_book)
        expect(books.last).to eq(old_book)
      end

      it "orders scholars by first name alphabetically" do
        scholar_z = create(:scholar, first_name: "Zaid", last_name: "Test")
        scholar_a = create(:scholar, first_name: "Ahmed", last_name: "Test")

        get :index, params: { q: "Test" }

        scholars = assigns(:results)[:scholars]
        expect(scholars.first).to eq(scholar_a)
        expect(scholars.last).to eq(scholar_z)
      end
    end

    context "breadcrumbs" do
      it "sets up search breadcrumbs" do
        expect(controller).to receive(:breadcrumb_for).with(
          I18n.t("navigation.search"),
          search_path
        )

        get :index
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
