# frozen_string_literal: true

require "rails_helper"

# The service looks scholars up by a `name` column that `scholars` does not
# have (Scholar#name is a reader over full_name), so every row that reaches a
# scholar lookup fails. These examples pin that behaviour (issue #607).
RSpec.describe MimhamImportService do
  let(:missing_column) { a_string_matching(/no such column: scholars\.name/) }

  def import(**options)
    described_class.new(csv_file: file_fixture("mimham/lectures.csv").to_s, **options).import
  end

  context "when importing" do
    it "creates nothing and reports every scholar lookup as a line error" do
      result = nil

      expect { result = import }.not_to change(Lecture, :count)
      expect(result).to include(created_count: 0, skipped_count: 1, existing_count: 0, scholars_created: 0)
      expect(result[:errors]).to contain_exactly(
        a_string_starting_with("Line 2: ").and(missing_column),
        a_string_starting_with("Line 3: ").and(missing_column),
        a_string_starting_with("Line 4: ").and(missing_column)
      )
    end

    it "does not queue an audio download" do
      expect { import }.not_to have_enqueued_job(MimhamAudioDownloadJob)
    end

    it "skips a row whose source_url is already imported" do
      existing = create(:lecture, source_url: "https://mimham.example/lectures/2")

      result = import

      expect(result[:existing_records]).to contain_exactly(a_hash_including(title: "خطبة موجودة", existing_id: existing.id))
      expect(result[:skipped_count]).to eq(2)
    end
  end

  context "with dry_run" do
    it "lists rows with an unseen source_url as new without creating them" do
      result = nil

      expect { result = import(dry_run: true) }.not_to change(Lecture, :count)
      expect(result).to include(dry_run: true, created_count: 0, would_create_count: 2)
      expect(result[:new_records].pluck(:title)).to eq([ "خطبة جديدة", "خطبة موجودة" ])
      expect(result[:errors]).to contain_exactly(a_string_starting_with("Line 4: ").and(missing_column))
    end
  end

  it "accepts an IO as well as a path" do
    result = file_fixture("mimham/lectures.csv").open { |file| described_class.new(csv_file: file, dry_run: true).import }

    expect(result[:would_create_count]).to eq(2)
  end

  it "rejects a CSV missing required columns" do
    result = described_class.new(csv_file: file_fixture("mimham/series.csv").to_s).import

    expect(result[:errors]).to eq([ "CSV missing required columns: kind" ])
  end

  it "reports a missing file" do
    expect(described_class.new(csv_file: nil).import[:errors]).to eq([ "No CSV file provided" ])
  end

  it "prints a report" do
    service = described_class.new(csv_file: file_fixture("mimham/lectures.csv").to_s, dry_run: true)
    service.import

    expect { service.print_report }.to output(/DRY RUN REPORT.*New records:\s+2.*خطبة جديدة/m).to_stdout
  end
end
