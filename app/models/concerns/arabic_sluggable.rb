module ArabicSluggable
  extend ActiveSupport::Concern

  def slugify_arabic(text)
    return unless text.present?

    text.downcase.gsub(/[^ا-ي0-9\s]/i, "").gsub(/\s+/, "-")
  end

  def slugify_arabic_advanced(text)
    return unless text.present?

    # Remove special characters except Arabic letters, numbers, and spaces
    # Then replace spaces with hyphens and remove any consecutive hyphens
    text.strip
        .gsub(/[^\p{Arabic}\w\s\-]/u, "") # Keep Arabic chars, word chars, spaces, hyphens
        .gsub(/\s+/, "-")                  # Replace spaces with hyphens
        .gsub(/-+/, "-")                   # Remove consecutive hyphens
        .gsub(/^-|-$/, "")                 # Remove leading/trailing hyphens
        .downcase
  end
end
