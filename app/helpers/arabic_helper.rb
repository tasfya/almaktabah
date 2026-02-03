module ArabicHelper
  # Arabic Unicode character ranges
  ARABIC_LETTERS = "\\p{Arabic}".freeze
  TASHKEEL_PATTERN = /[\p{M}&&\p{Arabic}]/u.freeze

  ARABIC_INDIC_DIGITS = "٠١٢٣٤٥٦٧٨٩".freeze
  EASTERN_ARABIC_DIGITS = "۰۱۲۳۴۵۶۷۸۹".freeze
  LATIN_DIGITS = "0123456789".freeze
  SHADDA = "ّ".freeze

  ARABIC_TO_LATIN = {
    "ا" => "a", "أ" => "a", "إ" => "i", "آ" => "aa", "ٱ" => "a",
    "ب" => "b", "ت" => "t", "ث" => "th", "ج" => "j", "ح" => "h",
    "خ" => "kh", "د" => "d", "ذ" => "dh", "ر" => "r", "ز" => "z",
    "س" => "s", "ش" => "sh", "ص" => "s", "ض" => "d", "ط" => "t",
    "ظ" => "z", "ع" => "a", "غ" => "gh", "ف" => "f", "ق" => "q",
    "ك" => "k", "ل" => "l", "م" => "m", "ن" => "n", "ه" => "h",
    "و" => "w", "ي" => "y", "ء" => "'", "ئ" => "'", "ؤ" => "'",
    "ى" => "a", "ة" => "h", "پ" => "p", "چ" => "ch", "ڤ" => "v",
    "گ" => "g", "ژ" => "zh",
    "ﻻ" => "la", "ﻼ" => "la", "ﻷ" => "la", "ﻸ" => "la",
    "ﻹ" => "la", "ﻺ" => "la", "ﻵ" => "la", "ﻶ" => "la",
    "ـ" => "", "ٓ" => "", "ٰ" => "",
    "َ" => "", "ً" => "", "ُ" => "", "ٌ" => "", "ِ" => "",
    "ٍ" => "", "ْ" => "", "ّ" => ""
  }.freeze

  def transliterate_arabic(text)
    return "" if text.blank?

    normalized = text.to_s
    normalized = normalized.unicode_normalize(:nfkc) if normalized.respond_to?(:unicode_normalize)
    normalized = remove_tatweel(normalized)
    normalized = normalized.tr(ARABIC_INDIC_DIGITS + EASTERN_ARABIC_DIGITS, LATIN_DIGITS * 2)

    output = +""
    last_segment = ""
    normalized.each_char do |char|
      if char == SHADDA
        output << last_segment unless last_segment.strip.empty?
        next
      end

      if char.match?(TASHKEEL_PATTERN)
        next
      end

      mapped = ARABIC_TO_LATIN[char] || char
      output << mapped
      last_segment = mapped if mapped != ""
    end

    output.squeeze(" ").strip
  end

  def remove_tashkeel(text)
    text.gsub(TASHKEEL_PATTERN, "")
  end

  def remove_tatweel(text)
    text.gsub(/\u0640/, "")
  end

  def remove_punctuation(text)
    text.gsub(/[[:punct:]\p{P}]+/u, " ")
  end

  def clean_for_slug(text, sep: "-")
    # Keep Arabic letters, digits, and ASCII letters; replace others with separator
    text.gsub(/[^0-9A-Za-z#{ARABIC_LETTERS}]+/u, sep)
  end
end
