# frozen_string_literal: true

module SeoHelper
  def meta_title
    [content_for(:title).presence, site_name].compact.join(" | ")
  end

  def meta_description
    content_for(:description).presence || default_description
  end

  def meta_image
    content_for(:image).presence || default_image
  end

  def canonical_url
    content_for(:canonical_url).presence || request.original_url.split("?").first
  end

  def site_name
    @domain&.name.presence || "المكتبة"
  end

  def default_description
    "المكتبة - مكتبة إسلامية شاملة تحتوي على محاضرات، دروس، كتب، فتاوى ومقالات لعلماء أهل السنة والجماعة"
  end

  def default_image
    "#{request.base_url}/icon.png"
  end

  def twitter_handle
    return nil unless site_info[:twitter_url].present?

    # Extract handle from URL (e.g., "https://x.com/Moh1Rz2H3?ref" -> "@Moh1Rz2H3")
    handle = site_info[:twitter_url].split("/").last&.split("?")&.first
    handle.present? ? "@#{handle.delete_prefix("@")}" : nil
  end

  def structured_data_organization
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      "name": site_name,
      "url": request.base_url,
      "logo": default_image,
      "sameAs": [
        site_info[:twitter_url],
        site_info[:youtube_url]
      ].compact
    }.to_json
  end

  def structured_data_for_lecture(lecture)
    return unless lecture
    return unless lecture.scholar

    {
      "@context": "https://schema.org",
      "@type": "VideoObject",
      "name": lecture.title,
      "description": lecture.description.presence || lecture.title,
      "thumbnailUrl": lecture.thumbnail.attached? ? rails_blob_url(lecture.thumbnail, only_path: false) : default_image,
      "uploadDate": lecture.published_at&.iso8601 || lecture.created_at.iso8601,
      "duration": lecture.duration ? "PT#{lecture.duration}S" : nil,
      "contentUrl": lecture_url(lecture, scholar_id: lecture.scholar.slug, kind: lecture.kind),
      "author": {
        "@type": "Person",
        "name": lecture.scholar.full_name
      },
      "publisher": {
        "@type": "Organization",
        "name": site_name,
        "logo": {
          "@type": "ImageObject",
          "url": default_image
        }
      }
    }.compact.to_json
  end

  def structured_data_for_article(article)
    return unless article

    {
      "@context": "https://schema.org",
      "@type": "Article",
      "headline": article.title,
      "description": article.description.presence || article.title,
      "image": article.thumbnail.attached? ? rails_blob_url(article.thumbnail, only_path: false) : default_image,
      "datePublished": article.published_at&.iso8601 || article.created_at.iso8601,
      "dateModified": article.updated_at.iso8601,
      "author": {
        "@type": "Person",
        "name": article.scholar&.full_name || site_name
      },
      "publisher": {
        "@type": "Organization",
        "name": site_name,
        "logo": {
          "@type": "ImageObject",
          "url": default_image
        }
      }
    }.to_json
  end

  def structured_data_for_news(news_item)
    return unless news_item

    {
      "@context": "https://schema.org",
      "@type": "NewsArticle",
      "headline": news_item.title,
      "description": news_item.description.presence || news_item.title,
      "image": news_item.thumbnail.attached? ? rails_blob_url(news_item.thumbnail, only_path: false) : default_image,
      "datePublished": news_item.published_at&.iso8601 || news_item.created_at.iso8601,
      "dateModified": news_item.updated_at.iso8601,
      "author": {
        "@type": "Organization",
        "name": site_name
      },
      "publisher": {
        "@type": "Organization",
        "name": site_name,
        "logo": {
          "@type": "ImageObject",
          "url": default_image
        }
      }
    }.to_json
  end

  def structured_data_for_book(book)
    return unless book

    {
      "@context": "https://schema.org",
      "@type": "Book",
      "name": book.title,
      "description": book.description.presence || book.title,
      "image": book.cover_image.attached? ? rails_blob_url(book.cover_image, only_path: false) : default_image,
      "author": {
        "@type": "Person",
        "name": book.scholar&.full_name || "Unknown"
      },
      "publisher": {
        "@type": "Organization",
        "name": site_name
      },
      "datePublished": book.published_at&.iso8601 || book.created_at.iso8601
    }.to_json
  end
end
