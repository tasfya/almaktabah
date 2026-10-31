# frozen_string_literal: true

require "rails_helper"

RSpec.describe LessonCsvImportService do
  let(:series) { create(:series) }

  def import(fixture, skip_duplicates: true)
    file_fixture("csv_imports/#{fixture}").open do |file|
      described_class.new(csv_file: file, series: series, skip_duplicates: skip_duplicates).import
    end
  end

  it "creates a lesson per titled row with its position" do
    result = import("lessons.csv")

    expect(result).to eq(created_count: 3, skipped_count: 2, errors: [])
    expect(series.lessons.unscope(:order).order(:id).pluck(:title, :position, :youtube_url)).to eq([
      [ "الدرس الأول", 1, "https://www.youtube.com/watch?v=lesson00001" ],
      [ "الدرس الثاني", 2, nil ],
      [ "Lesson Three", nil, nil ]
    ])
  end

  it "skips titles already in the series on re-import" do
    import("lessons.csv")

    expect(import("lessons.csv")).to eq(created_count: 0, skipped_count: 5, errors: [])
    expect(series.lessons.count).to eq(3)
  end

  it "only checks duplicate titles within the series" do
    create(:lesson, title: "Lesson Three")

    expect(import("lessons.csv")[:created_count]).to eq(3)
  end

  it "reports a row whose YouTube URL another lesson already uses and keeps going" do
    create(:lesson, youtube_url: "https://www.youtube.com/watch?v=lesson00001")

    result = import("lessons.csv")

    expect(result[:created_count]).to eq(3)
    expect(result[:errors]).to contain_exactly(a_string_starting_with("Line 2: Youtube url "))
    expect(series.lessons.where(youtube_url: "https://www.youtube.com/watch?v=lesson00001")).to be_empty
  end

  it "creates duplicate titles when skip_duplicates is off" do
    expect(import("lessons.csv", skip_duplicates: false)).to eq(created_count: 4, skipped_count: 1, errors: [])
  end

  it "accepts a CSV with only headers" do
    expect(import("headers_only.csv")).to eq(created_count: 0, skipped_count: 0, errors: [])
  end

  it "rejects a CSV without a title column" do
    expect(import("missing_title.csv")[:errors]).to eq([ "CSV must have a 'title' column" ])
  end

  it "reports a missing file" do
    expect(described_class.new(csv_file: nil, series: series).import[:errors]).to eq([ "No CSV file provided" ])
  end

  it "raises on malformed CSV" do
    expect { import("malformed.csv") }.to raise_error(CSV::MalformedCSVError)
  end
end
