class LessonsController < ApplicationController
  include Filterable
  before_action :set_lesson, only: [ :show, :play ]
  before_action :setup_lessons_breadcrumbs

  def index
    @q = Lesson.published.order(published_at: :desc).includes(:series).ransack(params[:q])
    @pagy, @lessons = pagy(@q.result(distinct: true), limit: 12)
    @series = Series.published.order(:title)
    @lessons = @lessons.ordered_by_lesson_number
    respond_to do |format|
      format.html
      format.json { render json: @lessons }
    end
  end

  def show
    @related_lessons = Lesson.published.by_series(@lesson.series_id)
                            .where.not(id: @lesson.id)
                            .recent
                            .limit(4)
  end

  def play
  end

  private

  def setup_lessons_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.lessons"), lessons_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.lessons"), lessons_path)
      if @lesson&.series
        breadcrumb_for(@lesson.series.title, series_path(@lesson.series))
      end
    end
  end

  def set_lesson
    @lesson = Lesson.published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lessons_path, alert: t("messages.lesson_not_found")
  end
end
