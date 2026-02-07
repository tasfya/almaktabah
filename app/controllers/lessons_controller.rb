class LessonsController < ApplicationController
  include Filterable
  before_action :set_lesson, only: [ :show ]
  before_action :setup_lessons_breadcrumbs

  def index
    @q = Lesson.for_domain_id(@domain.id)
      .published
      .includes(series: :scholar)
      .with_attached_thumbnail
      .with_attached_audio
      .with_attached_video
      .ransack(params[:q])
    @pagy, @lessons = pagy(@q.result(distinct: true))
  end

  def show
    @related_lessons = Lesson.for_domain_id(@domain.id)
                             .published
                             .where(series: @lesson.series)
                             .where.not(id: @lesson.id)
                             .recent
                             .limit(4)

    description = @lesson.description.to_s.truncate(MetaTags.config.description_limit)
    set_meta_tags(
      title: @lesson.title,
      description: description,
      canonical: canonical_url_for(@lesson),
      og: {
        title: @lesson.title,
        description: description,
        type: "article",
        url: canonical_url_for(@lesson)
      }
    )
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
    @lesson = Lesson.for_domain_id(@domain.id).published.includes(series: { scholar: :default_domain }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lessons_path, alert: t("messages.lesson_not_found")
  end
end
