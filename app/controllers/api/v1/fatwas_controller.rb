module Api
  module V1
    class FatwasController < ApiController
    def index
      page = params[:page]&.to_i || 1
      per_page = params[:per_page]&.to_i || 10

      fatwas = Fatwa.all

      if params[:title].present?
        fatwas = fatwas.where("LOWER(title) LIKE LOWER(?)", "%#{params[:title]}%")
      end

      # if params[:category].present?
      #   fatwas = fatwas.where("LOWER(category) LIKE LOWER(?)", "%#{params[:category]}%")
      # end

      total_items = fatwas.count
      total_pages = (total_items.to_f / per_page).ceil

      offset = (page - 1) * per_page
      paginated_fatwas = fatwas.offset(offset).limit(per_page)

      render json: {
        fatwas: ActiveModel::Serializer::CollectionSerializer.new(
          paginated_fatwas,
          serializer: FatwaSerializer
        ),
        meta: {
          current_page: page,
          per_page: per_page,
          total_items: total_items,
          total_pages: total_pages
          # categories: categories
        }
      }
    end

    def show
      fatwa = Fatwa.find(params[:id])
      render json: fatwa
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Fatwa not found" }, status: :not_found
    end

    def categories
      Fatwa.select(:category).distinct.pluck(:category)
    end

    def recent
      fatwas = Fatwa.order(published_date: :desc).limit(5)
      render json: fatwas
    end
    end
  end
end
