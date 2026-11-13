module TelegramImport
  # Folds Arabic text to a matching key that survives the schedule PDF's text
  # extraction, which mangles lam-alef ligatures and hamza forms
  # ("الإسلام" comes out as "اإلسالم", "الله" as "اهلل"). Dropping alef, lam,
  # hamza forms and whitespace makes both spellings fold to the same string.
  module ArabicFold
    DROPPED = /[\sاأإآٱلءـً-ْ]/

    def self.call(text)
      text.to_s.gsub(DROPPED, "")
    end
  end
end
