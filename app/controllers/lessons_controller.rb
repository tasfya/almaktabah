class LessonsController < ApplicationController
  before_action :set_lesson, only: [ :show ]
  before_action :setup_lessons_breadcrumbs, only: [ :show ]

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

  def legacy_index_redirect
    redirect_to series_index_path, status: :moved_permanently
  end

  def legacy_redirect
    lesson = Lesson.for_domain_id(@domain.id).published.find(params[:id])
    series = lesson.series
    scholar = series&.scholar
    if series && scholar
      redirect_to series_lesson_path(scholar.slug, series, lesson), status: :moved_permanently
    else
      redirect_to series_index_path, alert: t("messages.lesson_not_found")
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to series_index_path, alert: t("messages.lesson_not_found")
  end

  private

  def setup_lessons_breadcrumbs
    breadcrumb_for(t("breadcrumbs.series"), series_index_path)
    breadcrumb_for(@series.title, series_path(@series, scholar_id: @scholar.slug))
    breadcrumb_for(@lesson.title, series_lesson_path(@scholar, @series, @lesson))
  end

  def set_lesson
    @scholar = Scholar.includes(:default_domain).friendly.find(params[:scholar_id])
    @series = @scholar.series.friendly.for_domain_id(@domain.id).published.find(params[:series_id])
    @lesson = @series.lessons.for_domain_id(@domain.id).published.find(params[:id])
    if slug_mismatch?(:scholar_id, @scholar) || slug_mismatch?(:series_id, @series)
      redirect_to series_lesson_path(@scholar, @series, @lesson), status: :moved_permanently
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.info "Lesson lookup failed: #{e.message} (scholar_id=#{params[:scholar_id]}, series_id=#{params[:series_id]}, id=#{params[:id]})"
    redirect_to series_index_path, alert: t("messages.lesson_not_found")
  end
end
