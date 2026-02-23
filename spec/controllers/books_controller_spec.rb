# frozen_string_literal: true

require "rails_helper"

RSpec.describe BooksController, type: :controller do
  before(:each) do
    Faker::UniqueGenerator.clear
    request.host = "localhost"
  end

  let(:domain) { create(:domain, host: "localhost") }
  let!(:scholar) { create(:scholar) }
  let!(:published_book) { create(:book, published: true, published_at: 1.day.ago, scholar: scholar) }

  before do
    allow(controller).to receive(:set_domain)
    controller.instance_variable_set(:@domain, domain)

    create(:domain_assignment, domain: domain, assignable: published_book)
  end

  describe "GET #show" do
    context "when accessed via old scholar slug" do
      it "redirects to canonical URL with 301" do
        old_slug = scholar.slug
        scholar.update!(first_name: "NewUniqueName", last_name: "NewUniqueLast", full_name: "NewUniqueName NewUniqueLast")

        get :show, params: { scholar_id: old_slug, id: published_book.to_param }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(book_path(scholar, published_book))
      end
    end

    context "when accessed via old book slug" do
      it "redirects to canonical URL with 301" do
        old_slug = published_book.slug
        published_book.update!(title: "New Unique Book Title #{SecureRandom.hex(4)}")

        get :show, params: { scholar_id: scholar.to_param, id: old_slug }
        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(book_path(scholar, published_book))
      end
    end

    context "when book is not found" do
      it "redirects to books index" do
        get :show, params: { scholar_id: scholar.id, id: 999999 }
        expect(response).to redirect_to(books_path)
        expect(flash[:alert]).to eq(I18n.t("messages.book_not_found"))
      end
    end
  end

  describe "GET #legacy_redirect" do
    it "redirects to new book URL with 301" do
      get :legacy_redirect, params: { id: published_book.id }
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(book_path(scholar.slug, published_book))
    end

    it "redirects to books index when not found" do
      get :legacy_redirect, params: { id: 999999 }
      expect(response).to redirect_to(books_path)
      expect(flash[:alert]).to eq(I18n.t("messages.book_not_found"))
    end
  end
end
