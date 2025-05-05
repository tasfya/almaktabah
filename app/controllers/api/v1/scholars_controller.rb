module Api
  module V1
    class ScholarsController < ApiController
      def index
        scholars = Scholar.all
        render json: scholars
      end

      def show
        scholar = Scholar.find(params[:id])
        render json: scholar
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Scholar not found" }, status: :not_found
      end
    end
  end
end
