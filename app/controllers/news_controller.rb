class NewsController < ApplicationController
  include Filterable
  before_action :set_news, only: [ :show ]
  before_action :setup_news_breadcrumbs

  def index
    @q = News.ransack(params[:q])
    @pagy, @news = pagy(@q.result(distinct: true), limit: 12)
  end

  def show
    @news.increment!(:views) if @news.respond_to?(:views)
  end

  private

  def set_news
    @news = News.find_by!(slug: params[:id]) rescue News.find(params[:id])
  end

  def setup_news_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for("الأخبار", news_index_path)
    when "show"
      breadcrumb_for("الأخبار", news_index_path)
      breadcrumb_for(@news.title, news_path(@news))
    end
  end
end
