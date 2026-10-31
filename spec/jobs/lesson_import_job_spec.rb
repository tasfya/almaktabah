# frozen_string_literal: true

require "rails_helper"

RSpec.describe LessonImportJob, type: :job do
  let(:domain) { create(:domain) }
  let(:row) do
    {
      "title" => "الدرس الأول",
      "description" => "شرح المقدمة",
      "series_title" => " شرح الأصول الثلاثة ",
      "scholar_full_name" => " صالح الفوزان ",
      "position" => "1",
      "published_at" => "2024-02-01 10:00:00",
      "youtube_url" => "https://www.youtube.com/watch?v=lesson00001",
      "source_url" => "https://source.example.com/lessons/1",
      "audio_file_url" => "https://cdn.example.com/lessons/1.mp3",
      "thumbnail_url" => "https://cdn.example.com/lessons/1.jpg"
    }
  end

  before do
    stub_request(:get, "https://cdn.example.com/lessons/1.mp3").to_return(status: 200, body: Rails.root.join("spec/files/audio.mp3").binread)
    stub_request(:get, "https://cdn.example.com/lessons/1.jpg").to_return(status: 200, body: Rails.root.join("spec/files/thumbnail.jpg").binread)
  end

  it "creates the scholar, series and published lesson, assigns the domain and downloads its media" do
    lesson = described_class.perform_now(row, domain.id, 2)

    expect(lesson).to be_persisted
    expect(lesson).to have_attributes(
      title: "الدرس الأول", description: "شرح المقدمة", content_type: "audio", position: 1,
      youtube_url: "https://www.youtube.com/watch?v=lesson00001", source_url: "https://source.example.com/lessons/1",
      published: true, published_at: Time.zone.parse("2024-02-01 10:00:00")
    )
    expect(lesson.series).to have_attributes(title: "شرح الأصول الثلاثة")
    expect(lesson.series.scholar).to have_attributes(full_name: "صالح الفوزان", published: true)
    expect(lesson.domains).to include(domain)
    expect(lesson.audio.filename.to_s).to eq("1")
    expect(lesson.thumbnail).to be_attached
  end

  it "reuses the lesson, series and scholar when the same row is imported again" do
    first = described_class.perform_now(row, domain.id, 2)

    expect { described_class.perform_now(row, domain.id, 2) }
      .not_to change { [ Lesson.count, Series.count, Scholar.count ] }
    expect(described_class.perform_now(row, domain.id, 2)).to eq(first)
  end

  it "uses an existing scholar by id" do
    scholar = create(:scholar)

    lesson = described_class.perform_now(row.except("scholar_full_name").merge("scholar_id" => scholar.id), domain.id)

    expect(lesson.series.scholar).to eq(scholar)
  end

  it "creates an unpublished lesson when there is no publish date" do
    lesson = described_class.perform_now(row.merge("published_at" => "", "audio_file_url" => nil, "thumbnail_url" => nil), domain.id)

    expect(lesson).to have_attributes(published: false, published_at: nil)
    expect(lesson.audio).not_to be_attached
  end

  it "keeps a non-numeric position as nil" do
    lesson = described_class.perform_now(row.merge("position" => "first"), domain.id)

    expect(lesson.position).to be_nil
  end

  it "raises when the row has no series, since a lesson needs one" do
    expect { described_class.perform_now(row.except("series_title"), domain.id, 7) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "raises when a media download fails" do
    stub_request(:get, "https://cdn.example.com/lessons/1.mp3").to_return(status: 500)

    expect { described_class.perform_now(row, domain.id) }.to raise_error(RuntimeError, /Download failed: 500/)
  end
end
