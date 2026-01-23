# frozen_string_literal: true

module SitemapsHelper
  CHANGEFREQ = {
    articles: "monthly",
    books: "monthly",
    lectures: "monthly",
    series: "monthly",
    fatwas: "monthly",
    news: "weekly",
    lessons: "monthly",
    scholars: "monthly",
    static: "daily"
  }.freeze

  PRIORITY = {
    articles: 0.8,
    books: 0.8,
    lectures: 0.8,
    series: 0.7,
    fatwas: 0.7,
    news: 0.6,
    lessons: 0.7,
    scholars: 0.9,
    static: 1.0
  }.freeze

  def url_for_sitemap_record(record)
    case record
    when Article
      article_url(record, scholar_id: record.scholar.slug, host: request.host)
    when Book
      book_url(record, scholar_id: record.scholar.slug, host: request.host)
    when Lecture
      lecture_url(record, scholar_id: record.scholar.slug, kind: record.kind_for_url, host: request.host)
    when Series
      series_url(record, scholar_id: record.scholar.slug, host: request.host)
    when Fatwa
      fatwa_url(record, host: request.host)
    when News
      news_url(record, host: request.host)
    when Lesson
      lesson_url(record, host: request.host)
    when Scholar
      scholar_url(record, host: request.host)
    when Hash
      static_url_for(record[:loc])
    else
      raise ArgumentError, "Unknown sitemap record type: #{record.class}"
    end
  end

  def changefreq_for(type)
    CHANGEFREQ[type.to_sym] || "monthly"
  end

  def priority_for(type)
    PRIORITY[type.to_sym] || 0.5
  end

  private

  def static_url_for(loc)
    case loc
    when :root
      root_url(host: request.host)
    when :about
      about_url(host: request.host)
    else
      raise ArgumentError, "Unknown static URL location: #{loc}"
    end
  end
end
