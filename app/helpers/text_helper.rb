module TextHelper
  def normalize_for_slug(text, separator: "-")
    str = text.to_s.strip

    # Remove tashkeel (diacritics) if Arabic text is present
    str = remove_tashkeel(str) if respond_to?(:remove_tashkeel)

    # Remove all punctuation (Arabic + Latin)
    str = remove_punctuation(str)

    # Keep Arabic letters, digits, and ASCII letters; replace others with separator
    arabic_letters = defined?(ArabicHelper::ARABIC_LETTERS) ? ArabicHelper::ARABIC_LETTERS : '\u0600-\u06FF'
    str.gsub!(/[^0-9A-Za-z#{arabic_letters}]+/, separator)

    # Collapse repeated separators
    str.gsub!(/#{Regexp.escape(separator)}{2,}/, separator)

    # Strip leading/trailing separator
    str.gsub!(/^#{Regexp.escape(separator)}|#{Regexp.escape(separator)}$/, "")

    str.downcase
  end

  def remove_punctuation(text)
    text.gsub(/[[:punct:]\p{P}]+/u, " ")
  end
end
