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

    description = @book.description.to_s.truncate(MetaTags.config.description_limit)
    image_url = @book.cover_image.attached? ? url_for(@book.cover_image) : nil
    set_meta_tags(
      title: @book.title,
      description: description,
      canonical: canonical_url_for(@book),
      og: {
        title: @book.title,
        description: description,
        type: "book",
        url: canonical_url_for(@book),
        image: image_url
      }
    )
  end

  def legacy_redirect
    book = Book.for_domain_id(@domain.id).published.find(params[:id])
    redirect_to book_path(book.scholar.slug, book), status: :moved_permanently
  rescue ActiveRecord::RecordNotFound
    redirect_to books_path, alert: t("messages.book_not_found")
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
    @scholar = Scholar.includes(:default_domain).friendly.find(params[:scholar_id])
    @book = @scholar.books.friendly
                    .for_domain_id(@domain.id)
                    .published
                    .find(params[:id])
    if slug_mismatch?(:scholar_id, @scholar) || slug_mismatch?(:id, @book)
      redirect_to book_path(@scholar, @book), status: :moved_permanently
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to books_path, alert: t("messages.book_not_found")
  end
end
