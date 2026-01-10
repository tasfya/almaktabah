# frozen_string_literal: true

module TypesenseSearch
  class SearchHit
    attr_reader :highlights, :content_type

    def initialize(hit_data, content_type)
      @document = hit_data["document"] || {}
      @highlights = hit_data["highlights"] || []
      @content_type = content_type
    end

    def id = @document["id"]
    def slug = @document["slug"]
    def title = @document["title"] || @document["name"]
    def description = @document["description"] || @document["content_text"]
    def scholar_name = @document["scholar_name"]
    def scholar_slug = @document["scholar_slug"]
    def media_type = @document["media_type"]
    def read_time = @document["read_time"]
    def thumbnail_url = @document["thumbnail_url"]
    def audio_url = @document["audio_url"]
    def video_url = @document["video_url"]
    def duration = @document["duration"]
    def kind = @document["kind"]
    def lesson_count = @document["lesson_count"]
    def url = @document["url"]

    def highlighted_title
      find_highlight("title") || find_highlight("name") || title
    end

    def highlighted_description
      find_highlight("description") || find_highlight("content_text") || description
    end

    private

    def find_highlight(field)
      highlight = @highlights.find { |h| h["field"] == field }
      highlight&.dig("snippet")
    end
  end
end
