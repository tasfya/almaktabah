# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScholarLessonCsvImportService do
  let(:scholar) { create(:scholar) }

  def import(fixture)
    file_fixture("csv_imports/#{fixture}").open do |file|
      described_class.new(csv_file: file, scholar: scholar).import
    end
  end

  def lessons_by_series
    scholar.series.order(:id).to_h do |series|
      [ series.title, series.lessons.unscope(:order).order(:id).pluck(:title, :position) ]
    end
  end

  it "creates the series named in the file and their lessons" do
    result = import("scholar_lessons.csv")

    expect(result).to eq(created_count: 4, skipped_count: 3, series_created_count: 2, errors: [])
    expect(lessons_by_series).to eq(
      "شرح الأصول الثلاثة" => [ [ "الدرس الأول", 1 ], [ "الدرس الثاني", 2 ] ],
      "شرح كتاب التوحيد" => [ [ "الدرس الأول", 1 ], [ "No URL Lesson", nil ] ]
    )
  end

  it "adds lessons to an existing series of the scholar instead of creating one" do
    existing = create(:series, scholar: scholar, title: "شرح كتاب التوحيد")

    result = import("scholar_lessons.csv")

    expect(result[:series_created_count]).to eq(1)
    expect(existing.lessons.count).to eq(2)
  end

  it "does not reuse another scholar's series with the same title" do
    other = create(:series, title: "شرح كتاب التوحيد")

    import("scholar_lessons.csv")

    expect(other.lessons).to be_empty
    expect(scholar.series.pluck(:title)).to include("شرح كتاب التوحيد")
  end

  it "skips a row whose YouTube URL any lesson already has" do
    create(:lesson, youtube_url: "https://www.youtube.com/watch?v=scholar0003")

    result = import("scholar_lessons.csv")

    expect(result[:created_count]).to eq(3)
    expect(result[:skipped_count]).to eq(4)
  end

  # Re-import is idempotent only for rows that carry a YouTube URL: rows
  # without one are created again.
  it "re-imports only the rows without a YouTube URL" do
    import("scholar_lessons.csv")

    result = import("scholar_lessons.csv")

    expect(result).to eq(created_count: 1, skipped_count: 6, series_created_count: 0, errors: [])
    expect(Lesson.where(title: "No URL Lesson").count).to eq(2)
    expect(scholar.series.count).to eq(2)
  end

  it "rejects a CSV without both title and series columns" do
    expect(import("lessons.csv")[:errors]).to eq([ "CSV must have 'title' and 'series' columns" ])
    expect(scholar.series).to be_empty
  end

  it "reports a missing file" do
    expect(described_class.new(csv_file: nil, scholar: scholar).import[:errors]).to eq([ "No CSV file provided" ])
  end

  it "raises on malformed CSV" do
    expect { import("malformed.csv") }.to raise_error(CSV::MalformedCSVError)
  end
end
