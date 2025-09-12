class NewsController < ApplicationController
  include Filterable
  before_action :set_news, only: [ :show ]
  before_action :setup_news_breadcrumbs

  def index
    @q = News.for_domain_id(@domain.id).published.order(published_at: :desc).ransack(params[:q])
    @pagy, @news = pagy(@q.result(distinct: true))

    respond_to do |format|
      format.html
      format.json { render json: NewsSerializer.render(@news) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: NewsSerializer.render(@news) }
    end
  end

  private

  def set_news
    @news = News.friendly
                .for_domain_id(@domain.id)
                .published
                .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to news_index_path, alert: t("messages.news_not_found")
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
