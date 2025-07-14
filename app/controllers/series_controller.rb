class SeriesController < ApplicationController
  include Filterable
  before_action :set_series, only: [ :show ]
  before_action :setup_series_breadcrumbs

  def index
    @q = Series.for_domain(@domain).published.order(published_at: :desc).includes(:lessons).ransack(params[:q])
    @pagy, @series = pagy(@q.result(distinct: true), limit: 12)
  end

  def show
    @lessons = @series.lessons.for_domain(@domain).published.ordered_by_lesson_number
    @related_series = Series.for_domain(@domain).published.by_category(@series.category)
                           .where.not(id: @series.id)
                           .recent
                           .limit(4)
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
    @series = Series.for_domain(@domain).published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to series_index_path, alert: t("messages.series_not_found")
  end
end
