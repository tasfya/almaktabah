# frozen_string_literal: true

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://almaktabah.com"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  # Home page
  add root_path, priority: 1.0, changefreq: "daily"

  # Lectures
  add lectures_path, priority: 0.9, changefreq: "daily"
  Lecture.published.find_each do |lecture|
    add lecture_path(lecture, scholar_id: lecture.scholar.slug, kind: lecture.kind),
        lastmod: lecture.updated_at,
        priority: 0.8,
        changefreq: "weekly"
  end

  # Books
  add books_path, priority: 0.9, changefreq: "weekly"
  Book.published.find_each do |book|
    add book_path(book.scholar, book),
        lastmod: book.updated_at,
        priority: 0.8,
        changefreq: "monthly"
  end

  # Articles
  add articles_path, priority: 0.9, changefreq: "weekly"
  Article.published.find_each do |article|
    add article_path(article.scholar, article),
        lastmod: article.updated_at,
        priority: 0.7,
        changefreq: "weekly"
  end

  # News
  add news_index_path, priority: 0.9, changefreq: "daily"
  News.published.find_each do |news_item|
    add news_path(news_item),
        lastmod: news_item.updated_at,
        priority: 0.7,
        changefreq: "weekly"
  end

  # Fatwas
  add fatwas_path, priority: 0.9, changefreq: "weekly"
  Fatwa.published.find_each do |fatwa|
    add fatwa_path(fatwa.scholar, fatwa),
        lastmod: fatwa.updated_at,
        priority: 0.7,
        changefreq: "monthly"
  end

  # Scholars
  add scholars_path, priority: 0.8, changefreq: "monthly"
  Scholar.find_each do |scholar|
    add scholar_path(scholar),
        lastmod: scholar.updated_at,
        priority: 0.6,
        changefreq: "monthly"
  end

  # Series
  add series_index_path, priority: 0.8, changefreq: "weekly"
  Series.find_each do |series|
    scholar = series.scholar
    next unless scholar

    add series_path(series, scholar_id: scholar.slug),
        lastmod: series.updated_at,
        priority: 0.7,
        changefreq: "weekly"
  end
end
