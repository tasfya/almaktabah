module Api
  module V1
    class BooksController < ApiController
      def index
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 10

        books = Book.all

        if params[:title].present?
            books = books.where("LOWER(title) LIKE LOWER(?)", "%#{params[:title]}%")
        end

        if params[:category].present?
            books = books.where("LOWER(category) LIKE LOWER(?)", "%#{params[:category]}%")
        end

        total_items = books.count
        total_pages = (total_items.to_f / per_page).ceil

        offset = (page - 1) * per_page
        paginated_books = books.offset(offset).limit(per_page)

        render json: {
            books: ActiveModel::Serializer::CollectionSerializer.new(
                paginated_books,
                serializer: BookSerializer
            ),
            meta: {
                current_page: page,
                per_page: per_page,
                total_items: total_items,
                total_pages: total_pages,
                categories: categories
            }
        }
    end

      def show
        book = Book.find(params[:id])
        render json: book
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Book not found" }, status: :not_found
      end

      def categories
        Book.select(:category).distinct.pluck(:category)
      end

      def recent
        books = Book.order(published_date: :desc).limit(20)
        render json: books
      end

      def most_downloaded
        books = Book.order(downloads: :desc).limit(5)
        render json: books
      end

      def most_viewed
        books = Book.order(views: :desc).limit(5)
        render json: books
      end
    end
  end
end
