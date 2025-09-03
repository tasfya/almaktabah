module ArabicHelper
  # Arabic Unicode character ranges
  ARABIC_LETTERS = '\u0600-\u06FF'
  TASHKEEL_PATTERN = /[\u0610-\u061A\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]/

  ARABIC_TO_LATIN = {
    "ا" => "a", "ب" => "b", "ت" => "t", "ث" => "th",
    "ج" => "j", "ح" => "h", "خ" => "kh", "د" => "d",
    "ذ" => "dh", "ر" => "r", "ز" => "z", "س" => "s",
    "ش" => "sh", "ص" => "s", "ض" => "d", "ط" => "t",
    "ظ" => "z", "ع" => "a", "غ" => "gh", "ف" => "f",
    "ق" => "q", "ك" => "k", "ل" => "l", "م" => "m",
    "ن" => "n", "ه" => "h", "و" => "w", "ي" => "y",
    "ء" => "'", "ئ" => "'", "ؤ" => "'", "ى" => "a",
    "ة" => "h", "ـ" => "", "ٓ" => "", "َ" => "", "ً" => "",
    "ُ" => "", "ٌ" => "", "ِ" => "", "ٍ" => "", "ْ" => "", "ّ" => ""
  }

  def transliterate_arabic(text)
    text.chars.map { |char| ARABIC_TO_LATIN[char] || char }.join
  end

  def remove_tashkeel(text)
    text.gsub(TASHKEEL_PATTERN, "")
  end
end
