module ArabicSluggable
  extend ActiveSupport::Concern

  def slugify_arabic_advanced(text)
    return unless text.present?

    # Remove diacritics and normalize Arabic text
    text = text.to_s.strip

    # Replace spaces and underscores with hyphens
    text = text.gsub(/[\s_]+/, "-")

    # Remove consecutive hyphens
    text = text.gsub(/-+/, "-")

    # Remove leading and trailing hyphens
    text = text.gsub(/^-+|-+$/, "")

    arabic_diacritics = /[\u0610-\u061A\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]/
    text = text.gsub(arabic_diacritics, "")

    # Return the slug, fallback to random string if empty
    text.present? ? text : SecureRandom.hex(8)
  end
end
