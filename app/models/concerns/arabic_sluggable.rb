module ArabicSluggable
  extend ActiveSupport::Concern

  def slugify_arabic_advanced(text)
    return unless text.present?

    # Remove diacritics and normalize Arabic text
    text = text.to_s.strip

    # Remove English punctuation and special characters, keep Arabic letters and numbers
    text = text.gsub(/[^\p{Arabic}\p{N}\s\-_]/, "")

    # Replace spaces and underscores with hyphens
    text = text.gsub(/[\s_]+/, "-")

    # Remove consecutive hyphens
    text = text.gsub(/-+/, "-")

    # Remove leading and trailing hyphens
    text = text.gsub(/^-+|-+$/, "")

    # Return the slug, fallback to random string if empty
    text.present? ? text : SecureRandom.hex(8)
  end
end
