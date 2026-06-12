# frozen_string_literal: true

module JsonLdHelper
  def json_ld_tag(data)
    # Ruby's to_json escapes < and > as \u003c and \u003e, preventing XSS
    content_tag(:script, data.to_json.html_safe, type: "application/ld+json")
  end

  def website_json_ld
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      "name": @domain&.title.presence || "العلم",
      "url": root_url(host: request.host),
      "inLanguage": "ar",
      "potentialAction": {
        "@type": "SearchAction",
        "target": "#{root_url(host: request.host)}?q={search_term_string}",
        "query-input": "required name=search_term_string"
      }
    }
  end

  def breadcrumb_json_ld
    return nil unless respond_to?(:current_breadcrumbs)

    items = current_breadcrumbs.each_with_index.map do |crumb, index|
      path = crumb[:path].presence || request.path
      {
        "@type": "ListItem",
        "position": index + 1,
        "name": crumb[:name],
        "item": URI.join(root_url(host: request.host), path).to_s
      }
    end

    return nil if items.size < 2

    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": items
    }
  rescue StandardError => e
    Rails.logger.warn("breadcrumb_json_ld failed: #{e.class}: #{e.message}")
    nil
  end

  def article_json_ld(article)
    data = {
      "@context": "https://schema.org",
      "@type": "Article",
      "headline": article.title,
      "datePublished": article.published_at&.iso8601,
      "dateModified": article.updated_at&.iso8601,
      "publisher": publisher_json_ld,
      "mainEntityOfPage": {
        "@type": "WebPage",
        "@id": canonical_url_for
      }
    }
    if article.scholar.present?
      data[:author] = {
        "@type": "Person",
        "name": article.scholar.full_name
      }
    end
    data.compact
  end

  def book_json_ld(book)
    data = {
      "@context": "https://schema.org",
      "@type": "Book",
      "name": book.title,
      "description": book.description,
      "datePublished": book.published_at&.strftime("%Y"),
      "publisher": publisher_json_ld,
      "url": canonical_url_for
    }
    if book.scholar.present?
      data[:author] = {
        "@type": "Person",
        "name": book.scholar.full_name
      }
    end
    data[:image] = safe_attachment_url(book.cover_image)
    data.compact
  end

  def lecture_json_ld(lecture)
    type = lecture.video.attached? ? "VideoObject" : "AudioObject"
    data = {
      "@context": "https://schema.org",
      "@type": type,
      "name": lecture.title,
      "description": lecture.description,
      "datePublished": lecture.published_at&.iso8601,
      "duration": lecture.duration.present? ? "PT#{lecture.duration}S" : nil,
      "publisher": publisher_json_ld,
      "url": canonical_url_for
    }
    if lecture.scholar.present?
      data[:author] = {
        "@type": "Person",
        "name": lecture.scholar.full_name
      }
    end
    data[:thumbnailUrl] = safe_attachment_url(lecture.thumbnail)
    data[:contentUrl] = safe_attachment_url(lecture.video) || safe_attachment_url(lecture.audio)
    data.compact
  end

  def fatwa_json_ld(fatwa)
    question_text = fatwa.question.present? ? fatwa.question.to_plain_text : fatwa.title
    answer_text = fatwa.answer.present? ? fatwa.answer.to_plain_text : nil

    return nil unless answer_text.present?

    {
      "@context": "https://schema.org",
      "@type": "FAQPage",
      "mainEntity": [
        {
          "@type": "Question",
          "name": question_text.truncate(500),
          "acceptedAnswer": {
            "@type": "Answer",
            "text": answer_text.truncate(2000)
          }
        }
      ]
    }
  end

  def series_json_ld(series)
    data = {
      "@context": "https://schema.org",
      "@type": "Course",
      "name": series.title,
      "description": series.description,
      "url": canonical_url_for
    }
    if series.scholar.present?
      data[:provider] = {
        "@type": "Person",
        "name": series.scholar.full_name
      }
    end
    data.compact
  end

  def news_json_ld(news)
    data = {
      "@context": "https://schema.org",
      "@type": "NewsArticle",
      "headline": news.title,
      "datePublished": news.published_at&.iso8601,
      "dateModified": news.updated_at&.iso8601,
      "description": news.description,
      "publisher": publisher_json_ld,
      "mainEntityOfPage": {
        "@type": "WebPage",
        "@id": canonical_url_for
      }
    }
    data[:image] = safe_attachment_url(news.thumbnail)
    data[:author] = { "@type": "Person", "name": news.scholar&.full_name } if news.scholar.present?
    data.compact
  end

  private

  def safe_attachment_url(attachment)
    return nil unless attachment&.attached?
    url_for(attachment)
  rescue StandardError
    nil
  end

  def publisher_json_ld
    {
      "@type": "Organization",
      "name": @domain&.title.presence || request.host,
      "url": root_url(host: request.host)
    }
  end
end
