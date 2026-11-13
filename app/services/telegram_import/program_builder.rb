module TelegramImport
  # Builds the Program of an import manifest from the library records the
  # LibraryImporter created or linked: its ordered items, a placeholder Exam per
  # schedule exam, and one Cohort whose slots carry the schedule's dates.
  #
  # Per text the order is: matn, then each lesson followed by the transcripts
  # ending at it (hidden: learners may not see transcripts yet), and each exam
  # right after the lesson the schedule places it after. Like the library
  # import, it is create-only and keyed by TelegramImportRecord, so a re-run
  # creates nothing; with ONLY, texts must be built in program order.
  class ProgramBuilder
    Entry = Struct.new(:key, :kind, :text_key, :source, :hidden, keyword_init: true)

    def initialize(manifest:, only: nil, dry_run: true, io: $stdout)
      @manifest = manifest
      @source = manifest.fetch("source")
      @only = Array(only).map(&:to_s).reject(&:empty?)
      @dry_run = dry_run
      @io = io
      @report = LibraryImporter::Report.empty
    end

    def call
      run = -> { preflight!; build }
      @dry_run ? ActiveRecord::Base.while_preventing_writes(&run) : run.call
      print_report
      @report
    end

    private

    def config = @manifest.fetch("program")
    def zone = ActiveSupport::TimeZone[config.fetch("time_zone")]

    def texts
      @texts ||= begin
        keys = @manifest["texts"].map { _1["key"] }
        unknown = @only - keys
        raise PreflightError, "unknown text keys: #{unknown.join(', ')}" if unknown.any?

        selected = @only.empty? ? keys : keys.select { @only.include?(_1) }
        unless selected == keys.first(selected.size)
          raise PreflightError, "texts must be built in program order: ONLY must start with #{keys.first(selected.size).join(',')}"
        end
        @manifest["texts"].first(selected.size)
      end
    end

    # -- the ordered program --------------------------------------------------

    def entries
      @entries ||= begin
        selected = texts.map { _1["key"] }
        exams = schedule_exams.select { |exam| (exam["text_keys"] - selected).empty? }
        texts.flat_map do |text|
          [ book_entry(text["matn"], text["key"], hidden: false) ] +
            text["lessons"].flat_map do |lesson|
              [ Entry.new(key: "message:#{lesson['message_id']}", kind: :lesson, text_key: text["key"], source: lesson) ] +
                text["transcripts"].select { _1["to"] == lesson["n"] }.map { book_entry(_1, text["key"], hidden: true) } +
                exams.select { _1["after"] == { "text_key" => text["key"], "n" => lesson["n"] } }
                     .map { Entry.new(key: "exam:#{_1['index']}", kind: :exam, source: _1) }
            end
        end.tap { |list| check_placed!(exams, list) }
      end
    end

    def book_entry(book, text_key, hidden:)
      Entry.new(key: "message:#{book['message_id']}", kind: :book, text_key: text_key, source: book, hidden: hidden)
    end

    def check_placed!(exams, list)
      placed = list.map(&:key)
      missing = exams.map { "exam:#{_1['index']}" } - placed
      if missing.any?
        raise PreflightError, "#{missing.join(', ')} come after a lesson outside the selected texts; add the next text to ONLY"
      end

      transcripts = texts.flat_map { |text| text["transcripts"].map { "message:#{_1['message_id']}" } }
      unplaced = transcripts - placed
      raise PreflightError, "transcripts ending at no lesson: #{unplaced.join(', ')}" if unplaced.any?
    end

    def schedule_exams = @manifest["schedule"].select { _1["kind"] == "exam" }

    def lesson_dates
      @lesson_dates ||= @manifest["schedule"].select { _1["kind"] == "lesson" }
                                             .to_h { [ [ _1["text_key"], _1["n"] ], Date.parse(_1["date"]) ] }
    end

    # -- preflight ------------------------------------------------------------

    def preflight!
      problems = []
      problems << "program maps to a deleted record" if deleted?("program")
      problems << "cohort maps to a deleted record" if deleted?(cohort_key)

      library = entries.reject { _1.kind == :exam }
      unimported = library.reject { mapping(_1.key)&.record }
      problems << "not imported yet (run telegram_import:library): #{unimported.map(&:key).join(', ')}" if unimported.any?

      built = entries.map { "item:#{_1.key}" }.select { mapping(_1) }
      unless built == entries.first(built.size).map { "item:#{_1.key}" }
        problems << "existing program items are not a prefix of the program order; build texts in order"
      end

      missing_dates = entries.select { _1.kind == :lesson }.reject { lesson_dates.key?([ _1.text_key, _1.source["n"] ]) }
      problems << "no schedule date for: #{missing_dates.map(&:key).join(', ')}" if missing_dates.any?
      raise PreflightError, "preflight failed:\n  #{problems.join("\n  ")}" if problems.any?
    end

    # -- build ----------------------------------------------------------------

    def build
      program = find_or_create("program", "Program", config["title"]) do
        Program.create!(title: config["title"], description: config["description"], published: false)
      end
      cohort = find_or_create(cohort_key, "Cohort", config["cohort_name"]) do
        Cohort.create!(program: program, name: config["cohort_name"], starts_on: lesson_dates.values.min,
                       time_zone: config["time_zone"])
      end
      next_position = program ? (program.program_items.maximum(:position) || 0) : 0

      entries.each do |entry|
        item = mapping("item:#{entry.key}")&.record
        if item
          @report.skipped["ProgramItem"] += 1
        else
          next_position += 1
          item = create_item(program, entry, next_position)
        end
        create_slot(cohort, item, entry)
      end
    end

    def create_item(program, entry, position)
      act("create ProgramItem ##{position} #{entry.kind}#{' (hidden)' if entry.hidden}: #{title_of(entry)}")
      @report.created["ProgramItem"] += 1
      return if @dry_run

      reference = case entry.kind
      when :exam then { exam: exam_for(program, entry) }
      when :lesson then { lesson: mapping(entry.key).record }
      else { book: mapping(entry.key).record }
      end
      create_mapped("item:#{entry.key}") do
        ProgramItem.create!(program: program, position: position, kind: entry.kind, hidden: entry.hidden || false, **reference)
      end
    end

    def exam_for(program, entry)
      find_or_create(entry.key, "Exam", entry.source["title"]) do
        Exam.create!(program: program, title: entry.source["title"])
      end
    end

    def create_slot(cohort, item, entry)
      if cohort && item && CohortSlot.exists?(cohort: cohort, program_item: item)
        return @report.skipped["CohortSlot"] += 1
      end

      @report.created["CohortSlot"] += 1
      return if @dry_run

      CohortSlot.create!(cohort: cohort, program_item: item, **slot_dates(entry))
    end

    def slot_dates(entry)
      case entry.kind
      when :exam
        opens_at = Time.iso8601(entry.source["opens_at"]).in_time_zone(zone)
        { available_on: opens_at.to_date, opens_at: opens_at, closes_at: Time.iso8601(entry.source["closes_at"]) }
      when :lesson
        { available_on: lesson_dates.fetch([ entry.text_key, entry.source["n"] ]) }
      else
        n = entry.source["to"] || 1
        { available_on: lesson_dates.fetch([ entry.text_key, n ]) }
      end
    end

    # -- helpers --------------------------------------------------------------

    def cohort_key = "cohort:#{config['cohort_name']}"

    def find_or_create(external_id, type, label)
      return mapping(external_id).record if mapping(external_id)

      act("create #{type}: #{label}")
      @report.created[type] += 1
      create_mapped(external_id) { yield } unless @dry_run
    end

    def title_of(entry)
      entry.source["title"]
    end

    def deleted?(external_id)
      (row = mapping(external_id)) && row.record.nil?
    end

    def mapping(external_id)
      TelegramImportRecord.find_by(source: @source, external_id: external_id)
    end

    def create_mapped(external_id)
      ActiveRecord::Base.transaction do
        yield.tap do |record|
          TelegramImportRecord.create!(source: @source, external_id: external_id, record: record, outcome: "created")
        end
      end
    end

    def act(line)
      @report.actions << line
    end

    def print_report
      @io.puts(@dry_run ? "DRY RUN — nothing was written" : "PROGRAM BUILD")
      @report.actions.each { @io.puts("  #{_1}") }
      %i[created skipped].each { @io.puts("#{_1}: #{@report[_1].to_h}") }
    end
  end
end
