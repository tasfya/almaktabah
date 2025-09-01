class LecturesController < ApplicationController
  include Filterable
  before_action :set_lecture, only: [ :show ]
  before_action :setup_lectures_breadcrumbs

  ##
  # Lists published lectures in the current domain, ordered by most recent, and paginates the results.
  #
  # Builds a Ransack search (@q) scoped to the current domain and published lectures, orders by `published_at` descending,
  # and paginates the distinct results into `@lectures` with pagination metadata in `@pagy` (12 items per page).
  # Responds to HTML (default) and JSON (renders the paginated `@lectures` as JSON).
  # Instance variables set: `@q`, `@pagy`, `@lectures`.
  def index
    @q = Lecture.for_domain_id(@domain.id).published.order(published_at: :desc).ransack(params[:q])
    @pagy, @lectures = pagy(@q.result(distinct: true), limit: 12)

    respond_to do |format|
      format.html
      format.json { render json: @lectures }
    end
  end

  ##
  # Prepares related lectures for the show view.
  #
  # Populates @related_lectures with up to four published lectures from the same domain and category as
  # @lecture, excluding the current lecture, ordered by recency. This instance variable is intended for
  # display in the show template.
  #
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
    @lecture = Lecture.for_domain_id(@domain.id).published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to lectures_path, alert: t("messages.lecture_not_found")
  end
end
