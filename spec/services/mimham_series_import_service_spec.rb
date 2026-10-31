# frozen_string_literal: true

require "rails_helper"

RSpec.describe MimhamSeriesImportService do
  let(:scholar_name) { "محمد بن هادي" }

  def import(**options)
    described_class.new(csv_file: file_fixture("mimham/series.csv").to_s, **options).import
  end

  it "creates the scholar, the series and a lesson per complete row" do
    result = nil

    expect { result = import }.to change(Lesson, :count).by(3).and change(Series, :count).by(1).and change(Scholar, :count).by(1)
    expect(result).to include(created_count: 3, skipped_count: 1, series_created: 1, errors: [])
    series = Series.last
    expect(series).to have_attributes(title: "شرح السنة", published: false, scholar: have_attributes(full_name: scholar_name))
    expect(series.lessons.find_by(position: 1)).to have_attributes(
      title: "الدرس الأول", source_url: "https://mimham.example/lessons/1", duration: 3723
    )
  end

  it "queues an audio download for a row with an audio_url" do
    expect { import }.to have_enqueued_job(MimhamAudioDownloadJob).once
      .with("Lesson", kind_of(Integer), "https://cdn.mimham.example/l1.mp3")
  end

  it "adds lessons to the existing series of a scholar matched by full_name_alias" do
    scholar = create(:scholar, full_name: "Muhammad ibn Hadi", full_name_alias: scholar_name)
    series = create(:series, scholar: scholar, title: "شرح السنة")

    expect { import }.not_to change { [ Scholar.count, Series.count ] }
    expect(series.lessons.count).to eq(3)
  end

  it "skips a row whose source_url is already imported" do
    existing = create(:lesson, source_url: "https://mimham.example/lessons/2")

    result = import

    expect(result[:existing_records]).to contain_exactly(a_hash_including(title: "الدرس الثاني", existing_id: existing.id))
  end

  it "creates nothing when the same file is imported again" do
    import

    result = nil
    expect { result = import }.not_to change(Lesson, :count)
    expect(result).to include(created_count: 0, existing_count: 3, errors: [])
  end

  it "lists new rows in a dry run without creating them" do
    result = nil

    expect { result = import(dry_run: true) }.not_to change { [ Scholar.count, Series.count, Lesson.count ] }
    expect(result).to include(dry_run: true, created_count: 0, would_create_count: 3, errors: [])
    expect(result[:new_records].first).to include(series_title: "شرح السنة", lesson_number: 1, duration: "1:02:03")
  end

  it "rejects a CSV missing required columns" do
    result = described_class.new(csv_file: file_fixture("mimham/lectures.csv").to_s).import

    expect(result[:errors]).to eq([ "CSV missing required columns: series_title" ])
  end

  it "reports a missing file" do
    expect(described_class.new(csv_file: nil).import[:errors]).to eq([ "No CSV file provided" ])
  end

  it "prints a report" do
    service = described_class.new(csv_file: file_fixture("mimham/series.csv").to_s, dry_run: true)
    service.import

    expect { service.print_report }.to output(/DRY RUN REPORT.*New lessons:\s+3/m).to_stdout
  end
end
