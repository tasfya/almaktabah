class SeriesController < ApplicationController
  include Filterable
  before_action :set_series, only: [ :show ]
  before_action :setup_series_breadcrumbs

  ##
  # Displays a paginated, searchable list of published Series for the current domain.
  #
  # Builds a ransack search scoped to the current domain's published Series (eager-loading lessons and ordered by published_at desc),
  # paginates the results with Pagy (12 items per page) and exposes @q, @pagy, and @series for the view.
  # Responds to HTML and JSON — JSON renders the @series collection.
  # Uses params[:q] for search/filter parameters.
  def index
    @q = Series.for_domain_id(@domain.id).published.order(published_at: :desc).includes(:lessons).ransack(params[:q])
    @pagy, @series = pagy(@q.result(distinct: true), limit: 12)

    respond_to do |format|
      format.html
      format.json { render json: @series }
    end
  end

  ##
  # Loads published lessons belonging to the current series and domain into @lessons.
  # The lessons are filtered to the current domain, limited to published records, and ordered by lesson number.
  # Requires @series (set by before_action) and @domain to be present; sets the @lessons instance variable for the view.
  def show
    @lessons = @series.lessons.for_domain_id(@domain.id).published.ordered_by_lesson_number
  end

  private

  def setup_series_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.series"), series_index_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.series"), series_index_path)
      breadcrumb_for(@series.title, series_path(@series))
    end
  end

  def set_series
    @series = Series.for_domain_id(@domain.id).published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to series_index_path, alert: t("messages.series_not_found")
  end
end
