class NewsController < ApplicationController
  include Filterable

  def index
    @q = News.ransack(params[:q])
    @pagy, @news = pagy(@q.result(distinct: true), limit: 12)
  end

  def show
    @news = News.find_by!(slug: params[:id]) rescue News.find(params[:id])
    @news.increment!(:views) if @news.respond_to?(:views)
  end
end
