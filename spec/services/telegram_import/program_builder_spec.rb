require "rails_helper"

RSpec.describe TelegramImport::ProgramBuilder do
  let!(:scholar) { create(:scholar) }
  let(:manifest) { telegram_fixture_manifest(scholar: scholar) }
  let(:files_dir) { telegram_fixture_files(manifest) }
  let(:source) { "t.me/fixture_channel" }
  let(:riyadh) { ActiveSupport::TimeZone["Asia/Riyadh"] }

  before { TelegramImport::LibraryImporter.new(manifest: manifest, files_dir: files_dir, dry_run: false, io: StringIO.new).call }
  after { FileUtils.rm_rf(files_dir) }

  def build(dry_run: false, only: nil)
    described_class.new(manifest: manifest, only: only, dry_run: dry_run, io: StringIO.new).call
  end

  def lookup(external_id) = TelegramImportRecord.lookup(source, external_id)
  def program = lookup("program")
  def cohort = lookup("cohort:١٤٤٧–١٤٤٨")

  def counts
    [ Program, ProgramItem, Exam, Cohort, CohortSlot, TelegramImportRecord ].to_h { [ _1.name, _1.count ] }
  end

  def item_keys
    program.program_items.map do |item|
      item.exam? ? "exam #{item.exam.title}" : "message:#{TelegramImportRecord.find_by(record: item.lesson || item.book)&.external_id&.delete_prefix('message:')}"
    end
  end

  it "creates an unpublished program with one cohort" do
    build

    expect(program).to have_attributes(title: "برنامج تجريبي", description: "وصف البرنامج", published: false, pass_mark: 60)
    expect(cohort).to have_attributes(program: program, name: "١٤٤٧–١٤٤٨", starts_on: Date.new(2025, 11, 8), time_zone: "Asia/Riyadh")
  end

  it "orders matn, lessons, each transcript after its last lesson, and exams after the schedule's lesson" do
    build

    expect(item_keys).to eq([
      "message:102", "message:103",
      "message:106", "message:107", "message:110", "message:113", "message:116",
      "message:117", "message:118", "message:121", "message:125", "message:63", "message:66",
      "exam اختبار واجبنا نحو ما أمرنا الله به، القواعد الأربع، الأصول الستة",
      "exam اختبار الأصول الستة: من الدرس 1 إلى 3"
    ])
    expect(program.program_items.map(&:position)).to eq((1..15).to_a)
  end

  it "hides transcripts and shows matn and lessons" do
    build

    hidden = program.program_items.select(&:hidden).map { _1.book.title }
    expect(hidden).to contain_exactly("تفريغ شرح القواعد الأربع", "تفريغ شرح الأصول الستة من الدرس 1 إلى 2", "تفريغ شرح الأصول الستة الدرس 3")
  end

  it "creates placeholder exams without questions" do
    build

    expect(program.exams.map { [ _1.title, _1.questions.count ] }).to eq([
      [ "اختبار واجبنا نحو ما أمرنا الله به، القواعد الأربع، الأصول الستة", 0 ],
      [ "اختبار الأصول الستة: من الدرس 1 إلى 3", 0 ]
    ])
  end

  it "dates lessons and books from the schedule and exams from their windows in Riyadh time" do
    build
    slot = ->(external_id) { CohortSlot.find_by(cohort: cohort, program_item: program.program_items.find { TelegramImportRecord.find_by(record: _1.lesson || _1.book)&.external_id == external_id }) }

    expect(slot.call("message:106").available_on).to eq(Date.new(2025, 11, 9))
    expect(slot.call("message:113").available_on).to eq(Date.new(2025, 11, 11))
    expect(slot.call("message:116").available_on).to eq(Date.new(2025, 11, 11))
    expect(slot.call("message:125").available_on).to eq(Date.new(2025, 11, 16))

    first, last = cohort.exam_slots.to_a
    expect(first).to have_attributes(available_on: Date.new(2025, 11, 19),
                                     opens_at: riyadh.local(2025, 11, 19, 12, 3), closes_at: riyadh.local(2025, 11, 25, 22))
    expect(last).to have_attributes(available_on: Date.new(2026, 1, 5),
                                    opens_at: riyadh.local(2026, 1, 5), closes_at: riyadh.local(2026, 1, 8, 22))
    expect(cohort.enrollment_deadline).to eq(riyadh.local(2025, 11, 25, 22))
  end

  it "gives every item exactly one slot" do
    build

    expect(cohort.cohort_slots.count).to eq(15)
  end

  it "links the existing lesson the library import linked" do
    existing = create(:lesson, youtube_url: "https://www.youtube.com/live/w2c1tFJKqVg")
    TelegramImportRecord.find_by(external_id: "message:103").update!(record: existing, outcome: "linked")

    build

    expect(program.program_items.find_by(position: 2).lesson).to eq(existing)
  end

  it "creates nothing on a second run" do
    build
    before = counts

    report = build

    expect(report.created.values.sum).to eq(0)
    expect(counts).to eq(before)
  end

  it "writes nothing in a dry run and reports the plan" do
    before = counts

    report = build(dry_run: true)

    expect(counts).to eq(before)
    expect(report.created).to eq("Program" => 1, "Cohort" => 1, "Exam" => 2, "ProgramItem" => 15, "CohortSlot" => 15)
  end

  it "builds the first texts with ONLY, then appends the rest without moving existing positions" do
    build(only: %w[wajibuna qawaid])
    first = program.program_items.map { [ _1.position, _1.id ] }

    build

    expect(program.program_items.first(first.size).map { [ _1.position, _1.id ] }).to eq(first)
    expect(program.program_items.count).to eq(15)
  end

  it "leaves an exam out until the text of the lesson it follows is built" do
    build(only: %w[wajibuna qawaid])

    expect(program.program_items.exam).to be_empty
  end

  it "refuses to run when a built item or exam was deleted" do
    build
    item = program.program_items.exam.first
    exam = item.exam
    item.destroy!
    exam.destroy!
    before = counts

    expect { build }.to raise_error(TelegramImport::PreflightError, /mapped to deleted records: item:exam:1, exam:1/)
    expect(counts).to eq(before)
  end

  it "recreates a deleted slot of an existing item" do
    build
    cohort.cohort_slots.first.destroy!

    report = build

    expect(report.created).to eq("CohortSlot" => 1)
    expect(cohort.cohort_slots.count).to eq(15)
  end

  it "refuses texts out of program order" do
    expect { build(only: %w[qawaid]) }.to raise_error(TelegramImport::PreflightError, /ONLY must start with wajibuna/)
  end

  it "refuses to build texts whose lessons were not imported" do
    TelegramImportRecord.find_by(external_id: "message:110").destroy!

    expect { build }.to raise_error(TelegramImport::PreflightError, /not imported yet .*message:110/)
  end

  it "assigns the program only to the global default domain" do
    default = create(:domain, is_default: true)
    create(:domain)

    build

    expect(program.domains).to eq([ default ])
  end
end
