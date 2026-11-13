module TelegramImport
  # Builds the frozen import manifest for one program channel from a
  # `tdl chat export --all --with-content` JSON file, the schedule PDF as
  # `pdftotext -layout` text, and the channel's YAML config.
  #
  # Lessons and PDFs come from the current cycle (message id >=
  # cycle_start_message_id). A lesson or transcript range the current cycle has
  # not posted yet is taken from the previous cycle, which re-broadcasts the
  # same recordings. Exam posts are read only for their announced window;
  # their links and contents never enter the manifest.
  class ManifestBuilder
    class Error < StandardError; end

    TIME_ZONE = "Asia/Riyadh".freeze
    EXAM_CLOSE_HOUR = 22

    def initialize(export_path:, schedule_path:, config_path:)
      @messages = JSON.parse(File.read(export_path)).fetch("messages").sort_by { _1["id"] }
      @schedule_text = File.read(schedule_path)
      @config = YAML.load_file(config_path)
      @texts = @config.fetch("texts")
    end

    def call
      lessons = select_lessons
      warnings = []
      schedule = build_schedule(lessons, warnings)

      {
        "source" => @config.fetch("source"),
        "scholar_id" => @config.fetch("scholar_id"),
        "matn_author_name" => @config.fetch("matn_author_name"),
        "export_last_message_id" => @messages.last&.fetch("id"),
        "texts" => @texts.map { |text| text_entry(text, lessons.fetch(text["key"])) },
        "schedule" => schedule,
        "warnings" => warnings
      }
    end

    private

    def cycle_start = @config.fetch("cycle_start_message_id")
    def previous_cycle_start = @config.fetch("previous_cycle_start_message_id")

    def current?(message_id) = message_id >= cycle_start
    def previous?(message_id) = message_id >= previous_cycle_start && message_id < cycle_start

    def text_entry(text, lessons)
      {
        "key" => text["key"],
        "title" => text["title"],
        "series_title" => text["series_title"],
        "matn" => select_matn(text),
        "lessons" => lessons,
        "transcripts" => select_transcripts(text)
      }
    end

    # -- lessons --------------------------------------------------------------

    def select_lessons
      triplets = lesson_triplets.group_by { _1["key"] }
      missing = []
      selected = @texts.to_h do |text|
        by_n = (triplets[text["key"]] || []).group_by { _1["n"] }
        lessons = (1..text.fetch("expected_lessons")).filter_map do |n|
          pick = newest(by_n[n], &method(:current?)) || newest(by_n[n], &method(:previous?))
          missing << "#{text['key']} #{n}" unless pick
          pick&.except("key")
        end
        [ text["key"], lessons ]
      end
      raise Error, "no complete recording for: #{missing.join(', ')}" if missing.any?

      selected
    end

    def newest(candidates, &in_cycle)
      (candidates || []).select { in_cycle.call(_1["message_id"]) }.max_by { _1["message_id"] }
    end

    def lesson_triplets
      @messages.each_with_index.filter_map do |message, index|
        caption = TextCleaner.clean(message["text"])
        next unless message["file"].to_s.empty? && caption.start_with?("شرح") && caption.length < 150

        key = text_key_for(caption) or next
        following = @messages[index + 1, 3].select { _1["id"] - message["id"] <= 4 }
        audio = following.find { _1["file"].to_s.downcase.end_with?(".mp3") && _1["id"] - message["id"] <= 3 }
        video_id = following.lazy.map { VideoId.extract(_1["text"]) }.find(&:itself)
        next unless audio && video_id

        {
          "key" => key,
          "n" => TextCleaner.numbers(caption).last || 1,
          "message_id" => message["id"],
          "audio_message_id" => audio["id"],
          "audio_file" => audio["file"],
          "video_id" => video_id,
          "title" => TextCleaner.title(caption),
          "posted_on" => local_time(message["date"]).to_date.iso8601
        }
      end
    end

    # -- PDFs -----------------------------------------------------------------

    def pdfs
      @pdfs ||= @messages.filter_map do |message|
        file = message["file"].to_s
        next unless file.downcase.end_with?(".pdf")

        caption = TextCleaner.clean(message["text"])
        name = TextCleaner.clean(File.basename(file, ".*").tr("_", " "))
        kind = if caption.start_with?("متن") then "matn"
        elsif "#{caption} #{name}".include?("تفريغ") || name.start_with?("شرح") then "transcript"
        end
        key = text_key_for("#{caption} #{name}")
        next unless kind && key

        { "message_id" => message["id"], "file" => file, "key" => key, "kind" => kind,
          "title" => title_for(message["id"], caption, name, kind) }
      end
    end

    def title_for(message_id, caption, name, kind)
      title = @config.fetch("title_overrides", {})[message_id] || caption.presence || name
      title = TextCleaner.title(title)
      kind == "transcript" && !title.start_with?("تفريغ") ? "تفريغ #{title}" : title
    end

    def select_matn(text)
      matn = pdfs.select { _1["key"] == text["key"] && _1["kind"] == "matn" && current?(_1["message_id"]) }
                 .max_by { _1["message_id"] }
      raise Error, "no matn PDF for #{text['key']}" unless matn

      matn.slice("message_id", "file", "title")
    end

    def select_transcripts(text)
      expected = text.fetch("expected_lessons")
      of_text = pdfs.select { _1["key"] == text["key"] && _1["kind"] == "transcript" }
                    .map { with_range(_1, expected) }
      chosen = of_text.select { current?(_1["message_id"]) }
      covered = chosen.map { _1["to"] }.max || 0
      chosen += of_text.select { previous?(_1["message_id"]) && _1["from"] > covered } if covered < expected
      chosen.sort_by { [ _1["from"], _1["message_id"] ] }
    end

    def with_range(pdf, expected)
      numbers = TextCleaner.numbers(pdf["title"])
      from, to = numbers.empty? ? [ 1, expected ] : [ numbers.first, numbers[1] || numbers.first ]
      pdf.slice("message_id", "file", "title").merge("from" => from, "to" => to)
    end

    # -- schedule -------------------------------------------------------------

    def build_schedule(lessons, warnings)
      recorded = lessons.flat_map { |key, list| list.map { [ key, _1["n"] ] } }.to_set
      rows = ScheduleParser.new(@schedule_text, texts: @texts, start_year: @config.fetch("schedule_start_year")).rows
      announcements = exam_announcements
      exam_index = 0
      last_lesson = nil

      rows.filter_map do |row|
        case row["kind"]
        when "lesson"
          unless recorded.include?([ row["text_key"], row["n"] ])
            warnings << "schedule row #{row['text_key']} #{row['n']} (#{row['date']}) has no recording; dropped"
            next
          end
          last_lesson = row
          row.merge("date" => row["date"].iso8601)
        when "exam"
          exam_index += 1
          exam_entry(row, exam_index, last_lesson, announcements[exam_index - 1])
        else
          row
        end
      end
    end

    def exam_entry(row, index, last_lesson, announcement)
      raise Error, "exam #{index} comes before any lesson" unless last_lesson
      if announcement && announcement["text_keys"] != row["text_keys"]
        raise Error, "exam #{index}: PDF texts #{row['text_keys']} but post #{announcement['message_id']} " \
                     "announces #{announcement['text_keys']}"
      end

      expected = @texts.find { _1["key"] == row["text_keys"].last }.fetch("expected_lessons")
      range = row["range"] && [ row["range"].first, [ row["range"].last, expected ].min ]
      zone = ActiveSupport::TimeZone[TIME_ZONE]
      {
        "kind" => "exam",
        "index" => index,
        "title" => exam_title(row["text_keys"], range),
        "text_keys" => row["text_keys"],
        "range" => range,
        "after" => last_lesson.slice("text_key", "n"),
        "pdf_opens_on" => row["opens_on"].iso8601,
        "pdf_closes_on" => row["closes_on"].iso8601,
        "opens_at" => (announcement&.fetch("opens_at") || zone.local(row["opens_on"].year, row["opens_on"].month, row["opens_on"].day)).iso8601,
        "closes_at" => (announcement&.fetch("closes_at") || zone.local(row["closes_on"].year, row["closes_on"].month, row["closes_on"].day, EXAM_CLOSE_HOUR)).iso8601,
        "window_source" => announcement ? "announced" : "pdf",
        "announcement_message_id" => announcement&.fetch("message_id")
      }
    end

    def exam_title(text_keys, range)
      titles = text_keys.map { |key| @texts.find { _1["key"] == key }.fetch("title") }
      title = "اختبار #{titles.join('، ')}"
      range ? "#{title}: من الدرس #{range.first} إلى #{range.last}" : title
    end

    # Exam posts of the current cycle, in order. Only the posting time and the
    # announced closing date are kept.
    def exam_announcements
      zone = ActiveSupport::TimeZone[TIME_ZONE]
      @messages.filter_map do |message|
        text = TextCleaner.clean(message["text"])
        next unless current?(message["id"]) && text.match?(/\A(ال)?اختبار/) && text.include?("docs.google.com")
        raise Error, "exam post #{message['id']} does not close at 22:00 (العاشرة مساء)" unless text.include?("العاشرة مساء")

        day, month, year = TextCleaner.latin_digits(text)[%r{الموافق\s*(\d+\s*/\s*\d+\s*/\s*\d{4})}, 1]
                            &.split("/")&.map(&:to_i)
        raise Error, "exam post #{message['id']} has no Gregorian closing date" unless year

        { "message_id" => message["id"],
          "text_keys" => @texts.select { |t| text.lines.first.match?(Regexp.new(t["caption"])) }.map { _1["key"] },
          "opens_at" => local_time(message["date"]),
          "closes_at" => zone.local(year, month, day, EXAM_CLOSE_HOUR) }
      end
    end

    # -- helpers --------------------------------------------------------------

    def text_key_for(string)
      keys = @texts.select { string.match?(Regexp.new(_1["caption"])) }.map { _1["key"] }
      raise Error, "ambiguous text match #{keys.inspect}: #{string}" if keys.size > 1

      keys.first
    end

    def local_time(unix)
      Time.at(unix).in_time_zone(TIME_ZONE)
    end
  end
end
