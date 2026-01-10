# frozen_string_literal: true

class BooksController < ApplicationController
  include TypesenseListable
  before_action :set_book, only: [ :show ]
  before_action :setup_books_breadcrumbs

  def index
    typesense_collection_search("book")
  end

  def show
    @related_books = Book.for_domain_id(@domain.id)
                         .published.by_category(@book.category)
                         .where.not(id: @book.id)
                         .recent
                         .limit(4)
  end

  private

  def setup_books_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.books"), books_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.books"), books_path)
      breadcrumb_for(@book.title, book_path(@book.scholar, @book))
    end
  end

  def set_book
    @scholar = Scholar.friendly.find(params[:scholar_id])
    @book = @scholar.books.friendly
                    .for_domain_id(@domain.id)
                    .published
                    .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to books_path, alert: t("messages.book_not_found")
  end
end
