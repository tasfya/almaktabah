# frozen_string_literal: true

module SitemapsHelper
  LISTING_LOCS = %i[articles books lectures series fatwas news].freeze

  CHANGEFREQ = {
    articles: "monthly",
    books: "monthly",
    lectures: "monthly",
    series: "monthly",
    fatwas: "monthly",
    news: "weekly",
    lessons: "monthly",
    listings: "weekly",
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
    listings: 0.6,
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
      series_lesson_url(record.series, record, scholar_id: record.scholar.slug, host: request.host)
    when Hash
      LISTING_LOCS.include?(record[:loc]) ? listing_url_for(record[:loc]) : static_url_for(record[:loc])
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

  def listing_url_for(loc)
    case loc
    when :articles then articles_url(host: request.host)
    when :books then books_url(host: request.host)
    when :lectures then lectures_url(host: request.host)
    when :series then series_index_url(host: request.host)
    when :fatwas then fatwas_url(host: request.host)
    when :news then news_index_url(host: request.host)
    else raise ArgumentError, "Unknown listing URL location: #{loc}"
    end
  end

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
