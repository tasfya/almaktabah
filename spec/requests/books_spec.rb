require 'rails_helper'

RSpec.describe "Books API", type: :request do
  let(:domain) { Domain.find_or_create_by(host: "localhost") }
  let(:other_domain) { create(:domain, host: "other.com") }
  let(:scholar) { create(:scholar) }

  describe "GET /books.json" do
    context "with published books" do
      let!(:book1) { create(:book, published: true, author: scholar) }
      let!(:book2) { create(:book, published: true, author: scholar) }

      before do
        book1.assign_to(domain)
        book2.assign_to(domain)
        host! "localhost"
      end

      it "returns 200 status" do
        get books_path(format: :json)
        expect(response).to have_http_status(:ok)
      end

      it "returns correct Content-Type" do
        get books_path(format: :json)
        expect(response.content_type).to eq("application/json; charset=utf-8")
      end

      it "returns valid JSON" do
        get books_path(format: :json)
        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it "returns expected JSON structure" do
        get books_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Array)
        expect(json_response.length).to eq(2)

        book_data = json_response.first
        expect(book_data).to have_key("id")
        expect(book_data).to have_key("title")
        expect(book_data).to have_key("description")
        expect(book_data).to have_key("category")
        expect(book_data).to have_key("published_at")
        expect(book_data).to have_key("downloads")
        expect(book_data).to have_key("author")
        expect(book_data).to have_key("file_url")
        expect(book_data).to have_key("cover_image_url")

        expect(book_data["author"]).to have_key("id")
        expect(book_data["author"]).to have_key("name")
      end
    end

    context "with domain filtering" do
      let!(:book_for_domain) { create(:book, :without_domain, published: true, author: scholar) }
      let!(:book_for_other_domain) { create(:book, :without_domain, published: true, author: scholar) }

      before do
        book_for_domain.assign_to(domain)
        book_for_domain.save!
        book_for_other_domain.assign_to(other_domain)
        book_for_other_domain.save!
        host! "localhost"
      end

      it "returns only books for the current domain" do
        get books_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)
        expect(json_response.first["id"]).to eq(book_for_domain.id)
      end

      it "does not return books from other domains" do
        get books_path(format: :json)
        json_response = JSON.parse(response.body)

        book_ids = json_response.map { |b| b["id"] }
        expect(book_ids).not_to include(book_for_other_domain.id)
      end
    end

    context "with pagination" do
      let!(:books) { create_list(:book, 15, published: true, author: scholar) }

      before do
        books.each { |book| book.assign_to(domain) }
        host! "localhost"
      end

      it "returns paginated results (12 items per page)" do
        get books_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(12)
      end

      it "returns second page" do
        get books_path(format: :json, page: 2)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(3) # 15 total, 12 on first page, 3 on second
      end
    end

    context "with empty results" do
      before do
        domain
        host! "localhost"
      end

      it "returns empty array when no books exist" do
        get books_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response).to eq([])
      end
    end

    context "with unpublished books" do
      let!(:unpublished_book) { create(:book, published: false, author: scholar) }

      before do
        unpublished_book.assign_to(domain)
        host! "localhost"
      end

      it "does not return unpublished books" do
        get books_path(format: :json)
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(0)
      end
    end

    context "with media attachments" do
      let!(:book_with_attachments) { create(:book, published: true, author: scholar) }

      before do
        book_with_attachments.assign_to(domain)
        # Assuming file and cover_image are attached in factory or separately
        host! "localhost"
      end

      it "includes file_url when file is attached" do
        # This test assumes the factory attaches files or we need to attach them
        get books_path(format: :json)
        json_response = JSON.parse(response.body)

        book_data = json_response.first
        expect(book_data["file_url"]).to be_present
      end

      it "includes cover_image_url when cover image is attached" do
        get books_path(format: :json)
        json_response = JSON.parse(response.body)

        book_data = json_response.first
        expect(book_data["cover_image_url"]).to be_present
      end
    end
  end
end
