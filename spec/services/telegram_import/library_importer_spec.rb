require "rails_helper"

RSpec.describe TelegramImport::LibraryImporter do
  include ActiveJob::TestHelper

  let!(:scholar) { create(:scholar, full_name: "عبد الرزاق البدر") }
  let(:manifest) { telegram_fixture_manifest(scholar: scholar) }
  let(:files_dir) { telegram_fixture_files(manifest) }
  let(:io) { StringIO.new }

  after { FileUtils.rm_rf(files_dir) }

  def import(dry_run: false, only: nil, dir: files_dir)
    described_class.new(manifest: manifest, files_dir: dir, only: only, dry_run: dry_run, io: io).call
  end

  def counts
    [ Lesson, Series, Book, Scholar, TelegramImportRecord, ActiveStorage::Blob, DomainAssignment ]
      .to_h { [ _1.name, _1.unscoped.count ] }
  end

  def created(klass)
    TelegramImportRecord.created_records.where(record_type: klass.name).map(&:record)
  end

  it "creates unpublished series, lessons and books, each with a mapping row" do
    report = import

    expect(report.created).to eq("Series" => 3, "Lesson" => 7, "Book" => 6, "Scholar" => 1)
    expect(created(Series).map(&:title)).to contain_exactly(
      "شرح رسالة واجبنا — برنامج", "شرح القواعد الأربع — برنامج", "شرح الأصول الستة — برنامج"
    )
    expect(created(Series) + created(Lesson) + created(Book) + created(Scholar)).to all(have_attributes(published: false))
    expect(TelegramImportRecord.count).to eq(17)

    lesson = TelegramImportRecord.lookup("t.me/fixture_channel", "message:110")
    expect(lesson).to have_attributes(title: "شرح القواعد الأربع (2)", position: 2,
                                      youtube_url: "https://www.youtube.com/watch?v=AAAAAAAAAA2",
                                      source_url: "https://t.me/fixture_channel/110")
    expect(lesson.series.title).to eq("شرح القواعد الأربع — برنامج")
  end

  it "attaches audio and the PDFs and enqueues the audio optimization" do
    expect { import }.to have_enqueued_job(AudioOptimizationJob).exactly(7).times

    expect(created(Lesson).map { _1.audio.filename.to_s }).to include("001.mp3", "003.mp3")
    expect(created(Book)).to all(satisfy { _1.file.attached? })
  end

  it "gives matn books the new unpublished matn author and transcripts the scholar" do
    import

    author = TelegramImportRecord.lookup("t.me/fixture_channel", "scholar:matn_author")
    expect(author).to have_attributes(full_name: "محمد بن عبد الوهاب", published: false)
    expect(Book.find_by(title: "متن القواعد الأربع").scholar).to eq(author)
    expect(Book.find_by(title: "تفريغ شرح القواعد الأربع").scholar).to eq(scholar)
  end

  it "creates nothing on a second run" do
    import
    before = counts

    report = import

    expect(report.created.values.sum).to eq(0)
    expect(report.skipped).to eq("Lesson" => 7, "Book" => 6)
    expect(counts).to eq(before)
  end

  context "when a lesson with the same video already exists in another URL form" do
    let!(:existing) { create(:lesson, youtube_url: "https://www.youtube.com/live/w2c1tFJKqVg?si=x") }

    it "links it, leaves it unchanged and creates no series for its text" do
      attributes = existing.reload.attributes

      report = import

      expect(report.linked).to eq("Lesson" => 1)
      expect(existing.reload.attributes).to eq(attributes)
      expect(TelegramImportRecord.find_by(external_id: "message:103")).to have_attributes(record: existing, outcome: "linked")
      expect(Series.where(title: "شرح رسالة واجبنا — برنامج")).to be_empty
      expect(Lesson.unscoped.where("youtube_url LIKE ?", "%w2c1tFJKqVg%").count).to eq(1)
    end
  end

  it "never changes a record it did not create" do
    untouched = [ scholar, create(:book), create(:lesson) ].map(&:reload)
    snapshot = untouched.map(&:attributes)

    import

    expect(untouched.map { _1.reload.attributes }).to eq(snapshot)
  end

  it "aborts before any write when a series title is already used by the scholar" do
    create(:series, scholar: scholar, title: "شرح القواعد الأربع — برنامج")
    before = counts

    expect { import }.to raise_error(TelegramImport::PreflightError, /series title already used by this scholar: شرح القواعد الأربع — برنامج/)
    expect(counts).to eq(before)
  end

  it "aborts before any write when a book title already exists" do
    create(:book, title: "متن الأصول الستة")
    before = counts

    expect { import }.to raise_error(TelegramImport::PreflightError, /book title already exists: متن الأصول الستة/)
    expect(counts).to eq(before)
  end

  it "aborts before any write when a file is missing" do
    dir = telegram_fixture_files(manifest, skip: [ 111 ])
    before = counts

    expect { import(dir: dir) }.to raise_error(TelegramImport::PreflightError, /file missing for message 111/)
    expect(counts).to eq(before)
  ensure
    FileUtils.rm_rf(dir)
  end

  it "attaches the missing audio of a lesson it created in an interrupted run" do
    import
    lesson = TelegramImportRecord.lookup("t.me/fixture_channel", "message:107")
    lesson.audio.purge

    report = import

    expect(report.completed).to eq("Lesson" => 1)
    expect(lesson.reload.audio).to be_attached
    expect(report.created.values.sum).to eq(0)
  end

  it "writes, uploads and enqueues nothing in a dry run, and reports the same plan" do
    before = counts

    report = nil
    expect { report = import(dry_run: true, dir: nil) }.not_to have_enqueued_job
    expect(counts).to eq(before)
    expect(report.created).to eq("Series" => 3, "Lesson" => 7, "Book" => 6, "Scholar" => 1)
    expect(io.string).to start_with("DRY RUN")
  end

  it "imports only the selected texts" do
    report = import(only: %w[qawaid])

    expect(report.created).to eq("Series" => 1, "Lesson" => 3, "Book" => 2, "Scholar" => 1)
  end

  it "rejects an unknown text key" do
    expect { import(only: %w[nope]) }.to raise_error(TelegramImport::PreflightError, "unknown text keys: nope")
  end

  it "reports domains the after-save callback assigned" do
    create(:domain, is_default: true)

    report = import(only: %w[qawaid])

    expect(report.warnings).to include(a_string_matching(/Series \d+ was auto-assigned to domains/))
  end
end
