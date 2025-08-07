class HomeController < ApplicationController
  def index
    @recent_lessons = Lesson.for_domain_id(@domain.id).published.limit(6).ordered_by_lesson_number
    @recent_books = Book.for_domain_id(@domain.id).published.recent.limit(6)
    @recent_lectures = Lecture.for_domain_id(@domain.id).published.recent.limit(6)
    @recent_news = News.for_domain_id(@domain.id).published.recent.limit(3)
    @recent_fatwas = Fatwa.for_domain_id(@domain.id).published.order(created_at: :desc).limit(5)
    @featured_series = Series.for_domain_id(@domain.id).published.recent.limit(4)

    @featured_lesson =  Lesson.for_domain_id(@domain.id).published.first
    @stats = {
      books_count: Book.for_domain_id(@domain.id).published.count,
      lectures_count: Lecture.for_domain_id(@domain.id).published.count,
      lessons_count: Lesson.for_domain_id(@domain.id).published.count,
      series_count: Series.for_domain_id(@domain.id).published.count,
      fatwas_count: Fatwa.for_domain_id(@domain.id).published.count
    }
  end
end
