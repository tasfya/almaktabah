class HomeController < ApplicationController
  def index
    @recent_lessons = Lesson.published.limit(6).ordered_by_lesson_number
    @recent_books = Book.published.recent.limit(6)
    @recent_lectures = Lecture.published.recent.limit(6)
    @recent_news = News.published.recent.limit(3)
    @recent_fatwas = Fatwa.published.order(created_at: :desc).limit(5)
    @featured_series = Series.published.recent.limit(4)

    @featured_lesson =  Lesson.published.first
    @stats = {
      books_count: Book.published.count,
      lectures_count: Lecture.published.count,
      lessons_count: Lesson.published.count,
      series_count: Series.published.count,
      fatwas_count: Fatwa.published.count
    }
  end
end
