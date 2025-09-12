class ArticlesController < ApplicationController
  include Filterable
  before_action :set_article, only: [ :show ]
  before_action :setup_articles_breadcrumbs

  def index
    @q = Article.for_domain_id(@domain.id).published.order(published_at: :desc).includes(:author).ransack(params[:q])
    @pagy, @articles = pagy(@q.result(distinct: true))

    respond_to do |format|
      format.html
      format.json { render json: ArticleSerializer.render(@articles) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: ArticleSerializer.render(@article) }
    end
  end

  private

  def setup_articles_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.articles"), articles_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.articles"), articles_path)
      breadcrumb_for(@article.title, article_path(@article))
    end
  end

  def set_article
    @article = Article.for_domain_id(@domain.id).published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to articles_path, alert: t("messages.article_not_found")
  end
end
