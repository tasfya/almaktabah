class SeriesController < ApplicationController
  include Filterable
  before_action :set_series, only: [ :show ]
  before_action :setup_series_breadcrumbs

  def index
    @q = Series.includes(:lessons).ransack(params[:q])
    @pagy, @series = pagy(@q.result(distinct: true), limit: 12)
    @categories = get_categories(Series)
  end

  def show
    @lessons = @series.lessons.recent
    @related_series = Series.by_category(@series.category)
                           .where.not(id: @series.id)
                           .recent
                           .limit(4)
  end

  private

  def setup_series_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for("السلاسل العلمية", series_index_path)
    when "show"
      breadcrumb_for("السلاسل العلمية", series_index_path)
      breadcrumb_for(@series.title, series_path(@series))
    end
  end

  def set_series
    @series = Series.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to series_index_path, alert: "السلسلة غير موجودة"
  end
end
