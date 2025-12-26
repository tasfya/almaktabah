# frozen_string_literal: true

class TypesenseSearchService
  # Value object wrapping Typesense hit data - NO database access
  class SearchHit
    attr_reader :highlights, :content_type

    def initialize(hit_data, content_type)
      @document = hit_data["document"]
      @highlights = hit_data["highlights"] || []
      @content_type = content_type
    end

    def id
      @document["id"]
    end

    def slug
      @document["slug"]
    end

    def title
      @document["title"] || @document["name"]
    end

    def highlighted_title
      find_highlight("title") || find_highlight("name") || title
    end

    def description
      @document["description"] || @document["content_text"]
    end

    def highlighted_description
      find_highlight("description") || find_highlight("content_text") || description
    end

    def scholar_name
      @document["scholar_name"]
    end

    def scholar_slug
      @document["scholar_slug"]
    end

    def media_type
      @document["media_type"]
    end

    def read_time
      @document["read_time"]
    end

    def thumbnail_url
      @document["thumbnail_url"]
    end

    def audio_url
      @document["audio_url"]
    end

    def video_url
      @document["video_url"]
    end

    def duration
      @document["duration"]
    end

    def kind
      @document["kind"]
    end

    def lesson_count
      @document["lesson_count"]
    end

    def url
      @document["url"]
    end

    private

    def find_highlight(field)
      highlight = @highlights.find { |h| h["field"] == field }
      highlight&.dig("snippet")
    end
  end
end
