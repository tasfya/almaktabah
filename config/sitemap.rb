# frozen_string_literal: true

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = ENV.fetch("SITEMAP_HOST", "https://almaktabah.com")
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"

# Get domain ID for filtering content (if specified)
domain_host = ENV.fetch("SITEMAP_DOMAIN_HOST", nil)
domain_id = domain_host ? Domain.find_by(host: domain_host)&.id : nil

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
  lectures = Lecture.published.includes(:scholar)
  lectures = lectures.for_domain_id(domain_id) if domain_id
  lectures.find_each do |lecture|
    scholar = lecture.scholar
    next unless scholar

    add lecture_path(lecture, scholar_id: scholar.slug, kind: lecture.kind),
        lastmod: lecture.updated_at,
        priority: 0.8,
        changefreq: "weekly"
  end

  # Books
  add books_path, priority: 0.9, changefreq: "weekly"
  books = Book.published.includes(:scholar)
  books = books.for_domain_id(domain_id) if domain_id
  books.find_each do |book|
    next unless book.scholar

    add book_path(book.scholar, book),
        lastmod: book.updated_at,
        priority: 0.8,
        changefreq: "monthly"
  end

  # Articles
  add articles_path, priority: 0.9, changefreq: "weekly"
  articles = Article.published.includes(:scholar)
  articles = articles.for_domain_id(domain_id) if domain_id
  articles.find_each do |article|
    next unless article.scholar

    add article_path(article.scholar, article),
        lastmod: article.updated_at,
        priority: 0.7,
        changefreq: "weekly"
  end

  # News
  add news_index_path, priority: 0.9, changefreq: "daily"
  news_items = News.published
  news_items = news_items.for_domain_id(domain_id) if domain_id
  news_items.find_each do |news_item|
    add news_path(news_item),
        lastmod: news_item.updated_at,
        priority: 0.7,
        changefreq: "weekly"
  end

  # Fatwas
  add fatwas_path, priority: 0.9, changefreq: "weekly"
  fatwas = Fatwa.published.includes(:scholar)
  fatwas = fatwas.for_domain_id(domain_id) if domain_id
  fatwas.find_each do |fatwa|
    next unless fatwa.scholar

    add fatwa_path(fatwa),
        lastmod: fatwa.updated_at,
        priority: 0.7,
        changefreq: "monthly"
  end

  # Scholars
  add scholars_path, priority: 0.8, changefreq: "monthly"
  scholars = Scholar.all
  # If filtering by domain, only include scholars who have content in that domain
  if domain_id
    scholar_ids = [
      Lecture.for_domain_id(domain_id).distinct.pluck(:scholar_id),
      Book.for_domain_id(domain_id).distinct.pluck(:author_id),
      Article.for_domain_id(domain_id).distinct.pluck(:author_id),
      Fatwa.for_domain_id(domain_id).distinct.pluck(:scholar_id),
      Series.for_domain_id(domain_id).distinct.pluck(:scholar_id)
    ].flatten.uniq
    scholars = scholars.where(id: scholar_ids)
  end
  scholars.find_each do |scholar|
    add scholar_path(scholar),
        lastmod: scholar.updated_at,
        priority: 0.6,
        changefreq: "monthly"
  end

  # Series
  add series_index_path, priority: 0.8, changefreq: "weekly"
  series_collection = Series.includes(:scholar)
  series_collection = series_collection.for_domain_id(domain_id) if domain_id
  series_collection.find_each do |series|
    scholar = series.scholar
    next unless scholar

    add series_path(series, scholar_id: scholar.slug),
        lastmod: series.updated_at,
        priority: 0.7,
        changefreq: "weekly"
  end
end
