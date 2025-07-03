class LessonsController < ApplicationController
  include Filterable
  before_action :set_lesson, only: [ :show ]
  before_action :setup_lessons_breadcrumbs

  def index
    @q = Lesson.includes(:series).ransack(params[:q])
    @pagy, @lessons = pagy(@q.result(distinct: true), limit: 12)
    @series = Series.order(:title)
    @categories = get_categories(Lesson)
    @lessons = @lessons.ordered_by_lesson_number
    respond_to do |format|
      format.html
      format.json { render json: @lessons }
    end
  end

  def show
    @related_lessons = Lesson.by_series(@lesson.series_id)
                            .where.not(id: @lesson.id)
                            .recent
                            .limit(4)
  end

  def play
    @lesson = Lesson.find(params[:id])
  end

  private

  def setup_lessons_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.lessons"), lessons_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.lessons"), lessons_path)
      # Add series breadcrumb if lesson belongs to a series
      if @lesson&.series
        breadcrumb_for(@lesson.series.title, series_path(@lesson.series))
      end
      # Current lesson will be added in the view
    end
  end

  def set_lesson
    @lesson = Lesson.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lessons_path, alert: t("messages.lesson_not_found")
  end
end
