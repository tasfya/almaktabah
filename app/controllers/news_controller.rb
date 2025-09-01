class NewsController < ApplicationController
  include Filterable
  before_action :set_news, only: [ :show ]
  before_action :setup_news_breadcrumbs

  ##
  # Prepares a paginated, domain-scoped list of published news for the index view.
  #
  # Builds a Ransack search object scoped to the current domain and published items,
  # ordered by `published_at` descending, sets `@pagy` and `@news` for pagination,
  # and responds to HTML and JSON (JSON renders the `@news` collection).
  # The search parameters are taken from `params[:q]`.
  #
  # Instance variables set:
  # - @q    : Ransack search object
  # - @pagy : Pagination metadata
  # - @news : Paginated collection of news records
  def index
    @q = News.for_domain_id(@domain.id).published.order(published_at: :desc).ransack(params[:q])
    @pagy, @news = pagy(@q.result(distinct: true), limit: 12)

    respond_to do |format|
      format.html
      format.json { render json: @news }
    end
  end

  ##
  # Renders the news show view for a single news item.
  #
  # Relies on the before_action `set_news` to load `@news` (by slug or numeric id) and
  # `setup_news_breadcrumbs` to add appropriate breadcrumbs; the action itself only
  # renders the default `show` template (or responds with the configured formats).
  def show
  end

  private

  def set_news
    @news = News.for_domain_id(@domain.id).published.find_by!(slug: params[:id]) rescue News.for_domain_id(@domain.id).published.find(params[:id])
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
