module Api
  module V1
    class ArticlesController < ApiController
      def index
        articles = Article.all
        render json: articles
      end

      def show
        article = Article.find(params[:id])
        render json: article
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Article not found" }, status: :not_found
      end
    end
  end
end
