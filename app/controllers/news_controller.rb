class NewsController < ApplicationController
  include Filterable
  before_action :set_news, only: [ :show ]
  before_action :setup_news_breadcrumbs

  def index
    @q = News.published.ransack(params[:q])
    @pagy, @news = pagy(@q.result(distinct: true), limit: 12)
  end

  def show
  end

  private

  def set_news
    @news = News.published.find_by!(slug: params[:id]) rescue News.published.find(params[:id])
  end

  def setup_news_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.news"), news_index_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.news"), news_index_path)
      breadcrumb_for(@news.title, news_path(@news))
    end
  end
end
