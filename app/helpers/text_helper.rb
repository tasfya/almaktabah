module TextHelper
  include ArabicHelper

  def normalize_for_slug(text, sep: "-")
    str = text.to_s.strip

    # Remove tashkeel (diacritics) if Arabic text is present
    str = remove_tashkeel(str)

    # Remove tatweel (U+0640) - Arabic elongation character
    str = remove_tatweel(str)

    # Remove all punctuation (Arabic + Latin)
    str = remove_punctuation(str)

    # Keep Arabic letters, digits, and ASCII letters; replace others with separator
    str = clean_for_slug(str, sep:)

    # Collapse repeated separators
    str.gsub!(/#{Regexp.escape(sep)}{2,}/, sep)

    # Strip leading/trailing separator
    str.gsub!(/^#{Regexp.escape(sep)}|#{Regexp.escape(sep)}$/, "")

    str.downcase
  end
end
