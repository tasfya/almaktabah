module Api
    module V1
      class NewsController < ApiController
        def index
            page = params[:page]&.to_i || 1
            per_page = params[:per_page]&.to_i || 10

            news = News.all

            if params[:title].present?
                news = news.where("LOWER(title) LIKE LOWER(?)", "%#{params[:title]}%")
            end

            total_items = news.count
            total_pages = (total_items.to_f / per_page).ceil

            offset = (page - 1) * per_page
            paginated_news = news.offset(offset).limit(per_page)

            render json: {
                data: ActiveModel::Serializer::CollectionSerializer.new(
                    paginated_news,
                    serializer: NewsSerializer
                ),
                meta: {
                    current_page: page,
                    per_page: per_page,
                    total_items: total_items,
                    total_pages: total_pages
                }
            }
        end

        def show
          news = News.find_by!(slug: params[:id])
          render json: news
        rescue ActiveRecord::RecordNotFound
          render json: { error: "News not found" }, status: :not_found
        end
        def recent
            news = News.order(published_at: :desc).limit(10)
          render json: news
        end
      end
    end
end
