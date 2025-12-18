# frozen_string_literal: true

class TypesenseSearchService
  # Value object wrapping Typesense hit data - NO database access
  class SearchHit
    # Arabic route path segments (must match config/routes.rb)
    ROUTE_PATHS = {
      "book" => "الكتب",
      "lecture" => "المحاضرات",
      "series" => "السلاسل",
      "lesson" => "الدروس",
      "fatwa" => "الفتاوى",
      "news" => "الأخبار",
      "article" => "المقالات"
    }.freeze

    attr_reader :document, :highlights, :text_match, :content_type

    def initialize(hit_data, content_type)
      @document = hit_data["document"]
      @highlights = hit_data["highlights"] || []
      @text_match = hit_data["text_match"]
      @content_type = content_type
    end

    def id
      document["id"]
    end

    def slug
      document["slug"]
    end

    def title
      document["title"] || document["name"]
    end

    def highlighted_title
      find_highlight("title") || find_highlight("name") || title
    end

    def description
      document["description"] || document["content_text"]
    end

    def highlighted_description
      find_highlight("description") || find_highlight("content_text") || description
    end

    # Scholar fields (for content types with scholar association)
    def scholar_name
      document["scholar_name"]
    end

    def scholar_slug
      document["scholar_slug"]
    end

    def scholar_id
      document["scholar_id"]
    end

    # Lesson-specific fields
    def series_title
      document["series_title"]
    end

    def series_slug
      document["series_slug"]
    end

    def series_id
      document["series_id"]
    end

    def media_type
      document["media_type"]
    end

    def published_at
      Time.at(document["published_at_ts"]) if document["published_at_ts"]
    end

    # URL for linking to this result - built from stored slugs, no DB access
    def url
      path = ROUTE_PATHS.fetch(content_type) do
        raise ArgumentError, "Unknown content_type: #{content_type}"
      end

      case content_type
      when "lesson", "fatwa", "news"
        "/#{path}/#{slug}"
      when "book", "lecture", "series", "article"
        "/#{scholar_slug}/#{path}/#{slug}"
      else
        raise ArgumentError, "Unhandled content_type in url: #{content_type}"
      end
    end

    # Display label for this result
    def label
      case content_type
      when "lesson"
        series_title
      else
        title
      end
    end

    private

    def find_highlight(field)
      highlight = @highlights.find { |h| h["field"] == field }
      highlight&.dig("snippet")
    end
  end
end
