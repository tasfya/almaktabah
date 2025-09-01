class LessonsController < ApplicationController
  include Filterable
  before_action :set_lesson, only: [ :show ]
  before_action :setup_lessons_breadcrumbs

  ##
  # Lists lessons for the current domain, applying search and pagination.
  #
  # When a domain is present, builds a domain-scoped, published Lesson search (Ransack),
  # eager-loads associated series, and paginates results (12 per page). Sets `@q` to the
  # Ransack search object, `@pagy` to the pagination metadata, and `@lessons` to the page
  # of results. When no domain is present, sets `@lessons` to an empty array.
  #
  # Responds to HTML (default template) and JSON (renders `@lessons` as JSON).
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

  ##
  # Populates @related_lessons with up to four published lessons from the same domain and series as the current lesson (excluding the current lesson), ordered by recency.
  #
  # The collection is scoped to the controller's @domain, filtered to published lessons that share @lesson.series, excludes @lesson by id, ordered by recentness, and limited to 4 items.
  def show
    @related_lessons = Lesson.for_domain_id(@domain.id)
                             .published
                             .where(series: @lesson.series)
                             .where.not(id: @lesson.id)
                             .recent
                             .limit(4)
  end

  private

  ##
  # Adds appropriate breadcrumbs for lessons pages.
  # For the index action it adds a single "Lessons" breadcrumb; for the show action it adds the "Lessons" breadcrumb followed by a breadcrumb for the current lesson using @lesson.title and lesson_path(@lesson).
  # Requires @lesson to be present when called for the "show" action.
  def setup_lessons_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.lessons"), lessons_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.lessons"), lessons_path)
      breadcrumb_for(@lesson.title, lesson_path(@lesson))
    end
  end

  ##
  # Loads the requested Lesson into @lesson scoped to the current domain and only published records.
  #
  # If the lesson cannot be found, redirects to the lessons index with a localized
  # "lesson not found" alert.
  # 
  # Side effects:
  # - assigns @lesson when found
  # - may perform a redirect on ActiveRecord::RecordNotFound
  def set_lesson
    @lesson = Lesson.for_domain_id(@domain.id).published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lessons_path, alert: t("messages.lesson_not_found")
  end
end
