class LecturesController < ApplicationController
  include Filterable
  before_action :set_lecture, only: [ :show ]
  before_action :setup_lectures_breadcrumbs

  def index
    @q = Lecture.for_domain_id(@domain.id).published.order(published_at: :desc).ransack(params[:q])
    @pagy, @lectures = pagy(@q.result(distinct: true), limit: 12)
  end

  def show
    @related_lectures = Lecture.for_domain_id(@domain.id)
                               .published.by_category(@lecture.category)
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
    @lecture = Lecture.friendly.for_domain_id(@domain.id).published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lectures_path, alert: t("messages.lecture_not_found")
  end
end
