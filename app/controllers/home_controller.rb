class HomeController < ApplicationController
  def index
    @recent_lessons = Lesson.recent.limit(6)
    @recent_books = Book.recent.limit(6)
    @recent_lectures = Lecture.recent.limit(6)
    @recent_news = News.recent.limit(3)
    @recent_fatwas = Fatwa.order(created_at: :desc).limit(5)
    @featured_series = Series.recent.limit(4)

    @featured_lesson =  Lesson.first
    # Statistics for hero section
    @stats = {
      books_count: Book.count,
      lectures_count: Lecture.count,
      lessons_count: Lesson.count,
      series_count: Series.count,
      fatwas_count: Fatwa.count
    }
  end
end
