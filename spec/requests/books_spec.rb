# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Books", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }
  let!(:published_book) { create(:book, published: true, published_at: 1.day.ago, scholar: scholar) }

  before do
    host! "localhost"
    create(:domain_assignment, domain: domain, assignable: published_book)
  end

  describe "GET /:scholar_id/books/:id" do
    it "shows the book" do
      get book_path(scholar, published_book)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ERB::Util.html_escape(published_book.title))
    end

    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = scholar.slug
        scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get book_path(old_slug, published_book.to_param)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(book_path(scholar, published_book))
      end
    end

    context "when accessed via old book slug" do
      it "redirects to canonical URL with 301" do
        old_slug = published_book.slug
        published_book.update!(title: "New Unique Book Title #{SecureRandom.hex(4)}")

        get book_path(scholar.to_param, old_slug)
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(book_path(scholar, published_book))
      end
    end

    context "when book is not found" do
      it "redirects to books index" do
        get book_path(scholar.to_param, 999999)
        expect(response).to redirect_to(books_path)
        expect(flash[:alert]).to eq(I18n.t("messages.book_not_found"))
      end
    end
  end

  describe "GET /books/:id (legacy)" do
    it "redirects to new book URL with 301" do
      get "/books/#{published_book.id}"
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(book_path(scholar.slug, published_book))
    end

    it "redirects to books index when not found" do
      get "/books/999999"
      expect(response).to redirect_to(books_path)
      expect(flash[:alert]).to eq(I18n.t("messages.book_not_found"))
    end
  end
end
