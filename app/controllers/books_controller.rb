class BooksController < ApplicationController
  include Filterable
  before_action :set_book, only: [ :show ]
  before_action :setup_books_breadcrumbs

  def index
    @q = Book.includes(:author).ransack(params[:q])
    @pagy, @books = pagy(@q.result(distinct: true), limit: 12)
    @categories = get_categories(Book)

    respond_to do |format|
      format.html
      format.json { render json: @books }
    end
  end

  def show
    @book.increment!(:views) if @book.respond_to?(:views)
    @related_books = Book.by_category(@book.category)
                        .where.not(id: @book.id)
                        .recent
                        .limit(4)
  end

  private

  def setup_books_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for("الكتب", books_path)
    when "show"
      breadcrumb_for("الكتب", books_path)
      breadcrumb_for(@book.title, book_path(@book))
    end
  end

  def set_book
    @book = Book.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to books_path, alert: "الكتاب غير موجود"
  end
end
