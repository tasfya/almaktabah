module Api
  module V1
    class BenefitsController < ApiController
      def index
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 10

        benefits = Benefit.all

        if params[:title].present?
            benefits = benefits.where("LOWER(title) LIKE LOWER(?)", "%#{params[:title]}%")
        end

        if params[:category].present?
            benefits = benefits.where("LOWER(category) LIKE LOWER(?)", "%#{params[:category]}%")
        end

        total_items = benefits.count
        total_pages = (total_items.to_f / per_page).ceil

        offset = (page - 1) * per_page
        paginated_benefits = benefits.offset(offset).limit(per_page)

        render json: {
            benefits: ActiveModel::Serializer::CollectionSerializer.new(
                paginated_benefits,
                serializer: BenefitSerializer
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
        benefit = Benefit.find(params[:id])
        render json: benefit
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Benefit not found" }, status: :not_found
      end

      def categories
        Benefit.select(:category).distinct.pluck(:category)
      end

      def recent
        benefits = Benefit.order(published_date: :desc).limit(5)
        render json: benefits
      end

      def most_viewed
        benefits = Benefit.order(views: :desc).limit(5)
        render json: benefits
      end
    end
  end
end
