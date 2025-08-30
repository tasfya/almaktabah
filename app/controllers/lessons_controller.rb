class LessonsController < ApplicationController
  include Filterable
  before_action :set_lesson, only: [ :show ]
  before_action :setup_lessons_breadcrumbs

  def index
    if @domain
      @q = Lesson.for_domain_id(@domain.id).published.includes(:series).ransack(params[:q])
      @pagy, @lessons = pagy(@q.result(distinct: true), limit: 12)
    else
      @lessons = []
    end

    respond_to do |format|
      format.html
      format.json { render json: @lessons }
    end
  end

  def show
    @related_lessons = Lesson.for_domain_id(@domain.id)
                             .published
                             .where(series: @lesson.series)
                             .where.not(id: @lesson.id)
                             .recent
                             .limit(4)
  end

  private

  def setup_lessons_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.lessons"), lessons_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.lessons"), lessons_path)
      breadcrumb_for(@lesson.title, lesson_path(@lesson))
    end
  end

  def set_lesson
    @lesson = Lesson.for_domain_id(@domain.id).published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lessons_path, alert: t("messages.lesson_not_found")
  end
end
