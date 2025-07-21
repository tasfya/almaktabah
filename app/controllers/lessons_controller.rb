class LessonsController < ApplicationController
  include Filterable
  before_action :set_lesson, only: [ :show, :play ]
  before_action :setup_lessons_breadcrumbs

  def index
    @q = Lesson.for_domain_id(@domain.id).published.order(published_at: :desc).includes(:series).ransack(params[:q])
    @pagy, @lessons = pagy(@q.result(distinct: true), limit: 12)
    @series = Series.for_domain_id(@domain.id).published.order(:title)
    @lessons = @lessons.ordered_by_lesson_number
  end

  def show
    @related_lessons = Lesson
                            .for_domain_id(@domain.id)
                            .published
                            .by_series(@lesson.series_id)
                            .where.not(id: @lesson.id)
                            .limit(4)
  end

  def play
  end

  private

  def setup_lessons_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.series"), series_index_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.series"), series_index_path)
      if @lesson&.series
        breadcrumb_for(@lesson.series.title, series_index_path(@lesson.series))
      end
    end
  end

  def set_lesson
    @lesson = Lesson.for_domain_id(@domain.id).published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to series_index_path, alert: t("messages.lesson_not_found")
  end
end
