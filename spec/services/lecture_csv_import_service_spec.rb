# frozen_string_literal: true

require "rails_helper"

RSpec.describe LectureCsvImportService do
  let(:scholar) { create(:scholar) }

  def import(fixture, skip_duplicates: true)
    file_fixture("csv_imports/#{fixture}").open do |file|
      described_class.new(csv_file: file, scholar: scholar, skip_duplicates: skip_duplicates).import
    end
  end

  it "creates a lecture per titled row, parsing kind by name or number" do
    result = import("lectures.csv")

    expect(result).to eq(created_count: 4, skipped_count: 2, errors: [])
    expect(scholar.lectures.order(:id).pluck(:title, :kind, :youtube_url)).to eq([
      [ "خطبة الجمعة", "sermon", "https://www.youtube.com/watch?v=lecture0001" ],
      [ "Conference One", "conference", nil ],
      [ "A Benefit", "benefit", nil ],
      [ "Unknown Kind", nil, nil ]
    ])
  end

  it "skips titles the scholar already has, case-insensitively, on re-import" do
    import("lectures.csv")

    expect(import("lectures.csv")).to eq(created_count: 0, skipped_count: 6, errors: [])
    expect(scholar.lectures.count).to eq(4)
  end

  it "skips an existing title regardless of case" do
    create(:lecture, scholar: scholar, title: "a benefit")

    import("lectures.csv")

    expect(scholar.lectures.where("lower(title) = ?", "a benefit").count).to eq(1)
  end

  it "only checks duplicates against the importing scholar" do
    create(:lecture, title: "Conference One")

    expect(import("lectures.csv")[:created_count]).to eq(4)
  end

  it "creates duplicate titles when skip_duplicates is off" do
    result = import("lectures.csv", skip_duplicates: false)

    expect(result).to eq(created_count: 5, skipped_count: 1, errors: [])
    expect(scholar.lectures.where(title: "خطبة الجمعة").count).to eq(2)
  end

  it "rejects a CSV without a title column" do
    expect(import("missing_title.csv")).to eq(created_count: 0, skipped_count: 0, errors: [ "CSV must have a 'title' column" ])
    expect(scholar.lectures).to be_empty
  end

  it "reports a missing file" do
    result = described_class.new(csv_file: nil, scholar: scholar).import

    expect(result[:errors]).to eq([ "No CSV file provided" ])
  end

  it "raises on malformed CSV without creating anything" do
    expect { import("malformed.csv") }.to raise_error(CSV::MalformedCSVError)
    expect(scholar.lectures).to be_empty
  end
end
