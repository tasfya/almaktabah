require "rails_helper"

# Builds the program from the committed manifest, with plain library records
# standing in for the imported ones, to pin the real program's shape.
RSpec.describe TelegramImport::ProgramBuilder, "with the committed manifest" do
  let(:manifest) { JSON.parse(Rails.root.join("data/imports/mtoon_altawheed/manifest.json").read) }
  let(:source) { manifest["source"] }
  let(:lesson_keys) { {} }

  before do
    scholar = create(:scholar)
    series = Series.create!(scholar: scholar, title: "series", published: false)
    manifest["texts"].each do |text|
      text["lessons"].each do |lesson|
        record = Lesson.create!(series: series, title: lesson["title"], position: lesson["n"])
        lesson_keys[record.id] = "#{text['key']} #{lesson['n']}"
        TelegramImportRecord.create!(source: source, external_id: "message:#{lesson['message_id']}", record: record, outcome: "created")
      end
      [ text["matn"], *text["transcripts"] ].each do |book|
        record = Book.create!(title: book["title"], scholar: scholar)
        TelegramImportRecord.create!(source: source, external_id: "message:#{book['message_id']}", record: record, outcome: "created")
      end
    end
  end

  def build = described_class.new(manifest: manifest, dry_run: false, io: StringIO.new).call
  def program = TelegramImportRecord.lookup(source, "program")

  it "creates 281 items, 55 of them hidden transcripts, 14 exams and one slot per item" do
    report = build

    expect(report.created).to eq("Program" => 1, "Cohort" => 1, "Exam" => 14, "ProgramItem" => 281, "CohortSlot" => 281)
    expect(program.program_items.group(:kind).count).to eq("lesson" => 201, "book" => 66, "exam" => 14)
    expect(program.program_items.where(hidden: true).count).to eq(55)
  end

  it "places each exam right after the last lesson it covers" do
    build

    items = program.program_items.to_a
    after = items.each_with_index.select { |item, _| item.exam? }.map do |_, index|
      items[0...index].reverse.find(&:lesson?).then { lesson_keys[_1.lesson_id] }
    end
    expect(after).to eq([
      "usul_sitta 3", "thalatha_usul 17", "tawhid 20", "tawhid 40", "tawhid 54", "kashf 11", "nawaqid 11",
      "masail 11", "fadl_islam 19", "usul_iman 16", "usul_iman 30", "kabair 14", "kabair 30", "kabair 41"
    ])
  end

  it "dates التوحيد 54 on 2026-04-26 and starts the cohort on 2025-11-08" do
    build
    cohort = TelegramImportRecord.lookup(source, "cohort:1447-1448")
    tawhid_54 = lesson_keys.key("tawhid 54")

    expect(cohort.starts_on).to eq(Date.new(2025, 11, 8))
    expect(cohort.cohort_slots.joins(:program_item).find_by(program_items: { lesson_id: tawhid_54 }).available_on)
      .to eq(Date.new(2026, 4, 26))
  end

  it "refuses to build when existing items are not a prefix of the program order" do
    build
    TelegramImportRecord.find_by(source: source, external_id: "item:exam:1").destroy!

    expect { build }.to raise_error(TelegramImport::PreflightError, /not a prefix of the program order/)
  end
end
