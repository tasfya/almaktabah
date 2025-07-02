class LecturesController < ApplicationController
  include Filterable
  before_action :set_lecture, only: [ :show ]
  before_action :setup_lectures_breadcrumbs

  def index
    @q = Lecture.ransack(params[:q])
    @pagy, @lectures = pagy(@q.result(distinct: true), limit: 12)
    @categories = get_categories(Lecture)

    respond_to do |format|
      format.html
      format.json { render json: @lectures }
    end
  end

  def show
    @lecture.increment!(:views) if @lecture.respond_to?(:views)
    @related_lectures = Lecture.by_category(@lecture.category)
                              .where.not(id: @lecture.id)
                              .recent
                              .limit(4)
  end

  private

  def setup_lectures_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.lectures"), lectures_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.lectures"), lectures_path)
      breadcrumb_for(@lecture.title, lecture_path(@lecture))
    end
  end

  def set_lecture
    @lecture = Lecture.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lectures_path, alert: t("messages.lecture_not_found")
  end
end
