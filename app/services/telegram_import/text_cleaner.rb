module TelegramImport
  module TextCleaner
    INVISIBLE = /[​-‏‪-‮⁦-⁩﻿`]/
    ARABIC_DIGITS = "٠١٢٣٤٥٦٧٨٩"

    def self.clean(text)
      text.to_s.gsub(INVISIBLE, "").gsub(/[ \t]+/, " ").strip
    end

    def self.latin_digits(text)
      text.to_s.tr(ARABIC_DIGITS, "0123456789")
    end

    def self.numbers(text)
      latin_digits(clean(text)).scan(/\d+/).map(&:to_i)
    end
  end
end
