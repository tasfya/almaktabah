module Api
  module V1
    class BooksController < ApiController
      def index
        books = Book.all
        render json: books
      end

      def show
        book = Book.find(params[:id])
        render json: book
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Book not found" }, status: :not_found
      end
    end
  end
end
