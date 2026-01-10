# frozen_string_literal: true

module TypesenseSearch
  module Collections
    NAMES = %w[News Fatwa Lecture Series Article Book].freeze
    MAX_PER_PAGE = 51
    DEFAULT_PER_PAGE = 21

    KEYS = {
      "Book" => :books,
      "Lecture" => :lectures,
      "Series" => :series,
      "Fatwa" => :fatwas,
      "News" => :news,
      "Article" => :articles
    }.freeze

    SEARCHABLE_FIELDS = {
      "Book" => "title,description,content_text,scholar_name",
      "Lecture" => "title,description,content_text,scholar_name",
      "Series" => "title,description,content_text,scholar_name",
      "Fatwa" => "title,content_text,scholar_name",
      "News" => "title,description,content_text,scholar_name",
      "Article" => "title,content_text,scholar_name"
    }.freeze

    FACET_FIELDS = "content_type,scholar_name,media_type"

    def self.key_for(name)
      KEYS[name]
    end

    def self.name_for_type(type)
      type.to_s.capitalize
    end

    def self.index_for(name)
      NAMES.index(name)
    end
  end
end
