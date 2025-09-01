module Sluggable
  extend ActiveSupport::Concern

  included do
    extend FriendlyId
    friendly_id :title, use: [ :slugged, :history ]

    def normalize_friendly_id(value, sep: "-")
      str = value.to_s.strip
      # Remove Arabic tashkeel
      str.gsub!(/[\u0610-\u061A\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]/, "")
      # Transliterate diacritics to ASCII
      str = I18n.transliterate(str)
      # Replace non-word chars with separator
      str.gsub!(/[^0-9A-Za-z\u0600-\u06FF]+/, sep)
      # Collapse repeated separators
      str.gsub!(/#{Regexp.escape(sep)}{2,}/, sep)
      # Strip leading/trailing separator
      str.gsub!(/^#{Regexp.escape(sep)}|#{Regexp.escape(sep)}$/, "")
      str.downcase
    end

    def to_param
      slug
    end

    protected

    def should_generate_new_friendly_id?
      will_save_change_to_title? || slug.blank?
    end
  end
end
