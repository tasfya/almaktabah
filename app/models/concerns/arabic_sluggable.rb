module ArabicSluggable
  extend ActiveSupport::Concern

  private

  def slugify_arabic_advanced(text)
    return '' unless text.present?
    
    transliteration_map = {
      'ا' => 'a', 'ب' => 'b', 'ت' => 't', 'ث' => 'th',
      'ج' => 'j', 'ح' => 'h', 'خ' => 'kh', 'د' => 'd',
      'ذ' => 'dh', 'ر' => 'r', 'ز' => 'z', 'س' => 's',
      'ش' => 'sh', 'ص' => 's', 'ض' => 'd', 'ط' => 't',
      'ظ' => 'z', 'ع' => 'a', 'غ' => 'gh', 'ف' => 'f',
      'ق' => 'q', 'ك' => 'k', 'ل' => 'l', 'م' => 'm',
      'ن' => 'n', 'ه' => 'h', 'و' => 'w', 'ي' => 'y',
      'ى' => 'a', 'ة' => 't', 'أ' => 'a', 'إ' => 'i',
      'آ' => 'aa', 'ؤ' => 'u', 'ئ' => 'i'
    }
    
    text
      .strip
      .chars
      .map { |char| transliteration_map[char] || char }
      .join
      .gsub(/[^a-zA-Z0-9\s]/i, '')
      .gsub(/\s+/, '-')
      .gsub(/^-+|-+$/, '')
      .downcase
  end
end
