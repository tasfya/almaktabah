class SearchController < ApplicationController
  include Filterable
  before_action :setup_search_breadcrumbs

  def index
    @query = params[:q]&.strip
    @results = {}
    @total_results = 0

    if @query.present? && @query.length >= 2
      search_all_models
      @total_results = @results.values.map(&:count).sum
    elsif @query.present? && @query.length < 2
      flash.now[:alert] = "يجب أن يكون البحث مكونًا من حرفين على الأقل"
    end
  end

  private

  def setup_search_breadcrumbs
    breadcrumb_for(t("navigation.search"), search_path)
  end

  def search_all_models
    @results[:books] = search_books
    @results[:lectures] = search_lectures
    @results[:lessons] = search_lessons
    @results[:series] = search_series
    @results[:news] = search_news
    @results[:benefits] = search_benefits
    @results[:fatwas] = search_fatwas
    @results[:scholars] = search_scholars
  end

  def search_books
    Book.includes(:author).ransack(
      title_or_description_cont: @query
    ).result(distinct: true).recent.limit(5)
  end

  def search_lectures
    Lecture.ransack(
      title_or_description_cont: @query
    ).result(distinct: true).recent.limit(5)
  end

  def search_lessons
    Lesson.includes(:series).ransack(
      title_or_description_cont: @query
    ).result(distinct: true).limit(5)
  end

  def search_series
    Series.ransack(
      title_or_description_cont: @query
    ).result(distinct: true).recent.limit(5)
  end

  def search_news
    News.ransack(
      title_or_description_cont: @query
    ).result(distinct: true).recent.limit(5)
  end

  def search_benefits
    Benefit.ransack(
      title_or_description_cont: @query
    ).result(distinct: true).order(created_at: :desc).limit(5)
  end

  def search_fatwas
    Fatwa.ransack(
      title_cont: @query
    ).result(distinct: true).order(created_at: :desc).limit(5)
  end

  def search_scholars
    Scholar.ransack(
      first_name_or_last_name_cont: @query
    ).result(distinct: true).order(:first_name).limit(5)
  end
end
