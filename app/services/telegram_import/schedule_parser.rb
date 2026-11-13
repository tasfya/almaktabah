module TelegramImport
  # Parses the program schedule PDF after `pdftotext -layout` into ordered rows:
  #
  #   { "kind" => "lesson", "text_key" => "qawaid", "n" => 1, "date" => Date }
  #   { "kind" => "exam", "title" => String, "text_keys" => [..], "range" => [from, to] | nil,
  #     "opens_on" => Date, "closes_on" => Date }
  #   { "kind" => "break", "title" => String }
  #
  # The PDF writes dates as M/D without a year and in visual (right-to-left)
  # order, so a window "11/21-11/19" means 19 → 21 November. Years start at
  # `start_year` and advance whenever the month goes down.
  class ScheduleParser
    class Error < StandardError; end

    ROW = %r{\A(?<title>.*?)\s{2,}(?<dates>\d+\s*/\s*\d+(?:\s*-\s*\d+\s*/\s*\d+)?)\s{2,}}
    BREAK = /إجازة/

    # texts: [{ "key" =>, "schedule" => }]
    def initialize(text, texts:, start_year:)
      @lines = text.to_s.lines.map { |line| line.gsub(TextCleaner::INVISIBLE, "").strip }
      @matchers = texts.map { |t| [ t.fetch("key"), ArabicFold.call(t.fetch("schedule")) ] }
      @year = start_year
      @month = nil
    end

    def rows
      @rows ||= @lines.filter_map { |line| parse(line) }
    end

    private

    def parse(line)
      return { "kind" => "break", "title" => TextCleaner.clean(line) } if line.match?(BREAK)

      match = ROW.match(line) or return
      title = TextCleaner.clean(match[:title])
      dates = match[:dates].delete(" ").split("-").map { |d| d.split("/").map(&:to_i) }
      title.start_with?("اختبار") ? exam_row(title, dates) : lesson_row(title, dates.first)
    end

    def lesson_row(title, (month, day))
      keys = text_keys(title)
      raise Error, "schedule row matches #{keys.size} texts: #{title}" unless keys.one?

      n = TextCleaner.numbers(title).last || 1
      { "kind" => "lesson", "text_key" => keys.first, "n" => n, "date" => date(month, day) }
    end

    def exam_row(title, pairs)
      keys = text_keys(title)
      raise Error, "exam row matches no text: #{title}" if keys.empty?

      first, last = pairs.reverse.map { |month, day| date(month, day) }
      range = TextCleaner.numbers(title).minmax if TextCleaner.numbers(title).size == 2
      { "kind" => "exam", "title" => title, "text_keys" => keys, "range" => range,
        "opens_on" => first, "closes_on" => last || first }
    end

    def text_keys(title)
      folded = ArabicFold.call(title)
      @matchers.select { |_, needle| folded.include?(needle) }.map(&:first)
    end

    def date(month, day)
      @year += 1 if @month && month < @month
      @month = month
      Date.new(@year, month, day)
    end
  end
end
