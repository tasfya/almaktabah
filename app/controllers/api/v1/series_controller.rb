module Api
  module V1
    class SeriesController < ApiController
      def index
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 10

        series = Series.all

        if params[:title].present?
          series = series.where("LOWER(title) LIKE LOWER(?)", "%#{params[:title]}%")
        end

        if params[:category].present?
          series = series.where("LOWER(category) LIKE LOWER(?)", "%#{params[:category]}%")
        end

        total_items = series.count
        total_pages = (total_items.to_f / per_page).ceil

        offset = (page - 1) * per_page
        paginated_series = series.offset(offset).limit(per_page)

        render json: {
          series: ActiveModel::Serializer::CollectionSerializer.new(
            paginated_series,
            serializer: SeriesSerializer
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
        series = Series.find(params[:id])
        render json: series
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Series not found" }, status: :not_found
      end

      private

      def categories
        Series.select(:category).distinct.pluck(:category)
      end
    end
  end
end
