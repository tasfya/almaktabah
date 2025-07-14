class HomeController < ApplicationController
  def index
    @recent_lessons = Lesson.for_domain(@domain).published.limit(6).ordered_by_lesson_number
    @recent_books = Book.for_domain(@domain).published.recent.limit(6)
    @recent_lectures = Lecture.for_domain(@domain).published.recent.limit(6)
    @recent_news = News.for_domain(@domain).published.recent.limit(3)
    @recent_fatwas = Fatwa.for_domain(@domain).published.order(created_at: :desc).limit(5)
    @featured_series = Series.for_domain(@domain).published.recent.limit(4)

    @featured_lesson =  Lesson.for_domain(@domain).published.first
    @stats = {
      books_count: Book.for_domain(@domain).published.count,
      lectures_count: Lecture.for_domain(@domain).published.count,
      lessons_count: Lesson.for_domain(@domain).published.count,
      series_count: Series.for_domain(@domain).published.count,
      fatwas_count: Fatwa.for_domain(@domain).published.count
    }
  end
end
