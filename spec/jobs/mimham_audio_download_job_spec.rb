# frozen_string_literal: true

require "rails_helper"

RSpec.describe MimhamAudioDownloadJob, type: :job do
  let(:audio_url) { "https://cdn.mimham.example/audio/12.mp3" }

  before { stub_request(:get, audio_url).to_return(status: 200, body: "mp3-bytes") }

  it "attaches the audio to a lesson, named after its position" do
    lesson = create(:lesson, :without_audio, position: 4)

    described_class.perform_now("Lesson", lesson.id, audio_url)

    lesson.reload
    expect(lesson.audio.filename.to_s).to eq("4.mp3")
    expect(lesson.audio.content_type).to eq("audio/mpeg")
    expect(lesson.audio.download).to eq("mp3-bytes")
  end

  it "names lecture audio after the parameterized title, or the id when that is empty" do
    latin = create(:lecture, :without_audio, title: "Friday Sermon")
    arabic = create(:lecture, :without_audio, title: "خطبة")

    described_class.perform_now("Lecture", latin.id, audio_url)
    described_class.perform_now("Lecture", arabic.id, audio_url)

    expect(latin.reload.audio.filename.to_s).to eq("friday-sermon.mp3")
    expect(arabic.reload.audio.filename.to_s).to eq("#{arabic.id}.mp3")
  end

  it "does not download when the record already has audio" do
    lesson = create(:lesson)

    described_class.perform_now("Lesson", lesson.id, audio_url)

    expect(a_request(:get, audio_url)).not_to have_been_made
  end

  it "gives up quietly on a 404" do
    stub_request(:get, audio_url).to_return(status: 404)
    lesson = create(:lesson, :without_audio)

    expect { described_class.perform_now("Lesson", lesson.id, audio_url) }.not_to raise_error
    expect(lesson.reload.audio).not_to be_attached
  end

  it "discards the job when the record is gone" do
    expect { described_class.perform_now("Lesson", 0, audio_url) }.not_to raise_error
  end

  it "retries on a server error" do
    stub_request(:get, audio_url).to_return(status: 500)
    lesson = create(:lesson, :without_audio)

    expect { described_class.perform_now("Lesson", lesson.id, audio_url) }
      .to have_enqueued_job(described_class).with("Lesson", lesson.id, audio_url)
  end
end
