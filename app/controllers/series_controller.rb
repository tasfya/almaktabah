class SeriesController < ApplicationController
  include Filterable
  before_action :set_series, only: [ :show ]
  before_action :setup_series_breadcrumbs

  def index
    @q = Series.for_domain_id(@domain.id).published.order(published_at: :desc).includes(:lessons).ransack(params[:q])
    @pagy, @series = pagy(@q.result(distinct: true))

    respond_to do |format|
      format.html
      format.json { render json: SeriesSerializer.render(@series) }
    end
  end

  def show
    @lessons = @series.lessons.for_domain_id(@domain.id).published.ordered_by_lesson_number

    respond_to do |format|
      format.html
      format.json { render json: SeriesSerializer.render(@series) }
    end
  end

  private

  def setup_series_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.series"), series_index_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.series"), series_index_path)
      breadcrumb_for(@series.title, series_path(@series.scholar, @series))
    end
  end

  def set_series
    @scholar = Scholar.friendly.find(params[:scholar_id])
    @series = @scholar.series.friendly
                      .for_domain_id(@domain.id)
                      .published
                      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to series_index_path, alert: t("messages.series_not_found")
  end
end
