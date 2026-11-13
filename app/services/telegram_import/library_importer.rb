module TelegramImport
  class PreflightError < StandardError; end

  # Creates the library records of an import manifest: one unpublished Series
  # per text, its Lessons (audio attached), and unpublished Books for each matn
  # and transcript PDF. Every created or linked record gets a
  # TelegramImportRecord, so a re-run creates nothing.
  #
  # Create-only: an existing Lesson with the same YouTube video is linked
  # (a mapping row points at it) and never changed. Problems that would make a
  # run fail half-way are checked before the first write. A dry run performs
  # the same reads and writes nothing.
  class LibraryImporter
    Report = Struct.new(:created, :linked, :skipped, :completed, :warnings, :actions) do
      def self.empty = new(Hash.new(0), Hash.new(0), Hash.new(0), Hash.new(0), [], [])
    end

    def initialize(manifest:, files_dir: nil, only: nil, dry_run: true, io: $stdout)
      @manifest = manifest
      @source = manifest.fetch("source")
      @files_dir = files_dir && Pathname(files_dir)
      @only = Array(only).map(&:to_s).reject(&:empty?)
      @dry_run = dry_run
      @io = io
      @report = Report.empty
    end

    def call
      run = -> { preflight!; texts.each { import_text(_1) } }
      @dry_run ? ActiveRecord::Base.while_preventing_writes(&run) : run.call
      print_report
      @report
    end

    private

    def texts
      @texts ||= begin
        unknown = @only - @manifest["texts"].map { _1["key"] }
        raise PreflightError, "unknown text keys: #{unknown.join(', ')}" if unknown.any?

        @manifest["texts"].select { @only.empty? || @only.include?(_1["key"]) }
      end
    end

    # -- preflight -------------------------------------------------------------

    def preflight!
      problems = []
      scholar or problems << "scholar #{@manifest['scholar_id']} not found"

      texts.each do |text|
        if lessons_to_create(text).any? && !mapping("series:#{text['key']}") &&
           Series.exists?(scholar_id: @manifest["scholar_id"], title: text["series_title"])
          problems << "series title already used by this scholar: #{text['series_title']}"
        end
        books(text).each do |book|
          next if mapping("message:#{book['message_id']}")

          problems << "book title already exists: #{book['title']}" if Book.exists?(title: book["title"])
        end
      end

      titles = texts.flat_map { books(_1) }.map { _1["title"] }
      titles.tally.each { |title, count| problems << "book title repeated in the manifest: #{title}" if count > 1 }
      problems.concat(missing_files)
      raise PreflightError, "preflight failed:\n  #{problems.join("\n  ")}" if problems.any?
    end

    def missing_files
      return [] if @dry_run && @files_dir.nil?
      return [ "FILES_DIR is required for a real run" ] if @files_dir.nil?

      texts.flat_map do |text|
        lesson_ids = text["lessons"].select { needs_audio?(_1) }.map { _1["audio_message_id"] }
        book_ids = books(text).select { needs_file?(_1) }.map { _1["message_id"] }
        (lesson_ids + book_ids).reject { file_for(_1) }.map { "file missing for message #{_1} in #{@files_dir}" }
      end
    end

    def needs_audio?(lesson)
      record = mapping("message:#{lesson['message_id']}")
      return lesson_to_create?(lesson) unless record

      record.created? && !record.record.audio.attached?
    end

    def needs_file?(book)
      record = mapping("message:#{book['message_id']}")
      record.nil? || (record.created? && !record.record.file.attached?)
    end

    # -- import ----------------------------------------------------------------

    def import_text(text)
      text["lessons"].each { import_lesson(text, _1) }
      import_book(text["matn"], matn_author)
      text["transcripts"].each { import_book(_1, scholar) }
    end

    def import_lesson(text, lesson)
      external_id = "message:#{lesson['message_id']}"
      if (record = mapping(external_id))
        return complete_audio(record.record, lesson) if record.created? && !record.record.audio.attached?

        return @report.skipped["Lesson"] += 1
      end

      if (existing = existing_lesson(lesson["video_id"]))
        act("link Lesson #{existing.id} (published: #{existing.published}) ← #{external_id}")
        @report.linked["Lesson"] += 1
        map!(external_id, existing, "linked") unless @dry_run
        return
      end

      series = series_for(text)
      act("create Lesson #{text['key']} #{lesson['n']}: #{lesson['title']}")
      @report.created["Lesson"] += 1
      return if @dry_run

      created = create_mapped(external_id) do
        Lesson.create!(series: series, title: lesson["title"], position: lesson["n"],
                       youtube_url: VideoId.watch_url(lesson["video_id"]),
                       source_url: "https://#{@source}/#{lesson['message_id']}",
                       content_type: "audio", published: false)
      end
      attach(created.audio, lesson["audio_message_id"], lesson["audio_file"], "audio/mpeg")
      check_domains(created)
    end

    def complete_audio(lesson_record, lesson)
      act("attach missing audio to Lesson #{lesson_record.id}")
      @report.completed["Lesson"] += 1
      attach(lesson_record.audio, lesson["audio_message_id"], lesson["audio_file"], "audio/mpeg") unless @dry_run
    end

    def import_book(book, author)
      external_id = "message:#{book['message_id']}"
      if (record = mapping(external_id))
        return @report.skipped["Book"] += 1 if record.record.file.attached?

        act("attach missing file to Book #{record.record_id}")
        @report.completed["Book"] += 1
        attach(record.record.file, book["message_id"], book["file"], "application/pdf") unless @dry_run
        return
      end

      act("create Book: #{book['title']}")
      @report.created["Book"] += 1
      return if @dry_run

      created = create_mapped(external_id) { Book.create!(title: book["title"], scholar: author, published: false) }
      attach(created.file, book["message_id"], book["file"], "application/pdf")
      check_domains(created)
    end

    def series_for(text)
      external_id = "series:#{text['key']}"
      return mapping(external_id).record if mapping(external_id)

      once(external_id) do
        act("create Series: #{text['series_title']}")
        @report.created["Series"] += 1
        unless @dry_run
          create_mapped(external_id) do
            Series.create!(scholar: scholar, title: text["series_title"], published: false)
          end.tap { check_domains(_1) }
        end
      end
    end

    def matn_author
      external_id = "scholar:matn_author"
      return mapping(external_id).record if mapping(external_id)

      once(external_id) do
        act("create Scholar: #{@manifest['matn_author_name']} (unpublished)")
        @report.created["Scholar"] += 1
        create_mapped(external_id) { Scholar.create!(full_name: @manifest["matn_author_name"], published: false) } unless @dry_run
      end
    end

    # Memoizes per key, including the nil a dry run returns, so a planned
    # record is counted once.
    def once(key)
      @once ||= {}
      return @once[key] if @once.key?(key)

      @once[key] = yield
    end

    # -- helpers ---------------------------------------------------------------

    def scholar
      @scholar ||= Scholar.find_by(id: @manifest["scholar_id"])
    end

    def books(text)
      [ text["matn"], *text["transcripts"] ]
    end

    def lessons_to_create(text)
      text["lessons"].select { lesson_to_create?(_1) }
    end

    def lesson_to_create?(lesson)
      !mapping("message:#{lesson['message_id']}") && !existing_lesson(lesson["video_id"])
    end

    def existing_lesson(video_id)
      Lesson.unscoped.where("youtube_url LIKE ?", "%#{Lesson.sanitize_sql_like(video_id)}%")
            .find { VideoId.extract(_1.youtube_url) == video_id }
    end

    def mapping(external_id)
      TelegramImportRecord.find_by(source: @source, external_id: external_id)
    end

    def create_mapped(external_id)
      ActiveRecord::Base.transaction do
        yield.tap { map!(external_id, _1, "created") }
      end
    end

    def map!(external_id, record, outcome)
      TelegramImportRecord.create!(source: @source, external_id: external_id, record: record, outcome: outcome)
    end

    def file_for(message_id)
      @files_dir&.glob("#{message_id}_*")&.find(&:file?)
    end

    def attach(attachment, message_id, filename, content_type)
      path = file_for(message_id) or raise PreflightError, "file missing for message #{message_id}"
      attachment.attach(io: path.open("rb"), filename: filename, content_type: content_type)
    end

    def check_domains(record)
      domains = record.domain_assignments.pluck(:domain_id)
      @report.warnings << "#{record.class.name} #{record.id} was auto-assigned to domains #{domains}" if domains.any?
    end

    def act(line)
      @report.actions << line
    end

    def print_report
      @io.puts(@dry_run ? "DRY RUN — nothing was written" : "IMPORT RUN")
      @report.actions.each { @io.puts("  #{_1}") }
      %i[created linked completed skipped].each { @io.puts("#{_1}: #{@report[_1].to_h}") }
      @report.warnings.each { @io.puts("warning: #{_1}") }
    end
  end
end
