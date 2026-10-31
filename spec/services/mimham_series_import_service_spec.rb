# frozen_string_literal: true

require "rails_helper"

# Like MimhamImportService, this looks scholars up by a `name` column that
# `scholars` does not have, so no lesson is ever created. These examples pin
# that behaviour (issue #607).
RSpec.describe MimhamSeriesImportService do
  let(:missing_column) { a_string_matching(/no such column: scholars\.name/) }

  def import(**options)
    described_class.new(csv_file: file_fixture("mimham/series.csv").to_s, **options).import
  end

  it "creates no series or lesson and reports each row as a line error" do
    result = nil

    expect { result = import }.not_to change { [ Series.count, Lesson.count ] }
    expect(result).to include(created_count: 0, skipped_count: 1, series_created: 0)
    expect(result[:errors]).to contain_exactly(
      a_string_starting_with("Line 2: ").and(missing_column),
      a_string_starting_with("Line 3: ").and(missing_column),
      a_string_starting_with("Line 4: ").and(missing_column)
    )
  end

  it "skips a row whose source_url is already imported" do
    existing = create(:lesson, source_url: "https://mimham.example/lessons/2")

    result = import

    expect(result[:existing_records]).to contain_exactly(a_hash_including(title: "الدرس الثاني", existing_id: existing.id))
  end

  it "lists new rows in a dry run without creating them" do
    result = import(dry_run: true)

    expect(result).to include(dry_run: true, created_count: 0, would_create_count: 2)
    expect(result[:new_records].first).to include(series_title: "شرح السنة", lesson_number: 1, duration: "1:02:03")
    expect(result[:errors]).to contain_exactly(a_string_starting_with("Line 4: ").and(missing_column))
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

    expect { service.print_report }.to output(/DRY RUN REPORT.*New lessons:\s+2.*ERRORS/m).to_stdout
  end
end
