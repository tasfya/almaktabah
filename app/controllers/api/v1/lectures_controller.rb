module Api
  module V1
    class LecturesController < ApiController
      def index
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 10

        lectures = Lecture.all

        if params[:title].present?
            lectures = lectures.where("LOWER(title) LIKE LOWER(?)", "%#{params[:title]}%")
        end

        if params[:category].present?
            lectures = lectures.where("LOWER(category) LIKE LOWER(?)", "%#{params[:category]}%")
        end

        total_items = lectures.count
        total_pages = (total_items.to_f / per_page).ceil

        offset = (page - 1) * per_page
        paginated_lectures = lectures.offset(offset).limit(per_page)

        render json: {
            lectures: ActiveModel::Serializer::CollectionSerializer.new(
                paginated_lectures,
                serializer: LectureSerializer
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
        lecture = Lecture.find(params[:id])
        render json: lecture
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Lecture not found" }, status: :not_found
      end

      def categories
        Lecture.select(:category).distinct.pluck(:category)
      end

      def recent
        lectures = Lecture.order(published_date: :desc).limit(5)
        render json: lectures
      end

      def most_viewed
        lectures = Lecture.order(views: :desc).limit(5)
        render json: lectures
      end
    end
  end
end
