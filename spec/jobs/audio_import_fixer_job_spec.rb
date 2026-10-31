# frozen_string_literal: true

require "rails_helper"

# Durations are read with real ffmpeg (installed in CI). The attached audio is
# spec/files/audio.mp3 (58s); the "source" download is either the same file or
# a 10-second cut of it.
RSpec.describe AudioImportFixerJob, type: :job do
  let(:scholar) { create(:scholar) }
  let(:audio_url) { "https://cdn.example.com/audio/lecture-1.mp3" }
  let(:lecture) do
    create(:lecture, scholar: scholar, title: "محاضرة", category: "عقيدة", kind: :conference,
                     source_url: "https://source.example.com/1", duration: 58)
  end
  let(:row) do
    { "title" => "محاضرة", "category" => "عقيدة", "scholar_id" => scholar.id,
      "source_url" => "https://source.example.com/1", "kind" => "conference", "audio_file_url" => audio_url }
  end
  let(:full_audio) { Rails.root.join("spec/files/audio.mp3").binread }
  let(:short_audio) do
    path = Rails.root.join("tmp/audio_fixer_short_#{SecureRandom.hex(4)}.mp3").to_s
    system("ffmpeg", "-y", "-loglevel", "error", "-i", Rails.root.join("spec/files/audio.mp3").to_s,
           "-t", "10", "-c", "copy", path, exception: true)
    File.binread(path).tap { File.delete(path) }
  end

  def perform(data = row, type = "lecture", **options)
    described_class.perform_now(data, type, nil, 2, **options)
  end

  context "when the source audio has the same duration" do
    before { stub_request(:get, audio_url).to_return(status: 200, body: full_audio) }

    it "marks the record verified and keeps its audio" do
      original = lecture.audio.blob

      result = perform

      expect(result).to have_attributes(status: :verified, record: lecture, message: "Durations match")
      expect(lecture.reload.audio_verified_at).to be_present
      expect(lecture.audio.blob).to eq(original)
    end
  end

  context "when the source audio is a different length" do
    before { stub_request(:get, audio_url).to_return(status: 200, body: short_audio) }

    it "replaces the audio, updates the duration and queues optimization" do
      result = nil

      expect { result = perform }.to have_enqueued_job(AudioOptimizationJob).with(lecture).at_least(:once)
      expect(result).to have_attributes(status: :fixed, message: "Duration mismatch fixed")
      expect(result.old_duration).to be_within(1).of(58)
      expect(result.new_duration).to be_within(1).of(10)
      lecture.reload
      expect(lecture.audio.filename.to_s).to eq("lecture-1.mp3")
      expect(lecture.duration).to eq(result.new_duration.to_i)
      expect(lecture.audio_verified_at).to be_present
    end

    it "purges the optimized final audio so it is regenerated" do
      lecture.final_audio.attach(io: StringIO.new(full_audio), filename: "final.mp3", content_type: "audio/mpeg")

      perform

      expect(lecture.reload.final_audio).not_to be_attached
    end

    it "finds lessons by source_url" do
      lesson = create(:lesson, source_url: "https://source.example.com/lesson/1")

      result = perform({ "source_url" => lesson.source_url, "audio_file_url" => audio_url }, "Lesson")

      expect(result).to have_attributes(status: :fixed, record: lesson)
    end

    it "finds fatwas by scholar full name" do
      fatwa = create(:fatwa, scholar: scholar, title: "فتوى", category: "صلاة", source_url: "https://source.example.com/f/1")

      result = perform({ "title" => "فتوى", "category" => "صلاة", "scholar_full_name" => " #{scholar.full_name} ",
                         "source_url" => fatwa.source_url, "audio_file_url" => audio_url }, :fatwa)

      expect(result).to have_attributes(status: :fixed, record: fatwa)
    end

    it "re-checks an already verified record when forced" do
      lecture.update_column(:audio_verified_at, 1.day.ago)

      expect(perform(force: true)).to have_attributes(status: :fixed)
    end
  end

  describe "skips" do
    it "a row without audio_file_url" do
      expect(perform(row.except("audio_file_url"))).to have_attributes(status: :skipped, message: "No audio_file_url in row")
    end

    it "a row matching no record" do
      lecture
      expect(perform(row.merge("category" => "أخرى"))).to have_attributes(status: :skipped, message: "Record not found")
    end

    it "a record already verified" do
      lecture.update_column(:audio_verified_at, 1.day.ago)

      expect(perform).to have_attributes(status: :skipped, message: a_string_starting_with("Already verified at"))
      expect(a_request(:get, audio_url)).not_to have_been_made
    end

    it "a record without audio" do
      create(:lecture, :without_audio, scholar: scholar, title: "بلا صوت", source_url: nil, category: nil, kind: :sermon)

      result = perform({ "title" => "بلا صوت", "scholar_id" => scholar.id, "kind" => "sermon", "audio_file_url" => audio_url })

      expect(result).to have_attributes(status: :skipped, message: "No audio attached to record")
    end
  end

  it "raises for an unknown model type" do
    expect { perform(row, "book") }.to raise_error(ArgumentError, "Unknown model type: book")
  end

  it "raises when the download fails" do
    lecture
    stub_request(:get, audio_url).to_return(status: 404)

    expect { perform }.to raise_error(Down::NotFound)
    expect(lecture.reload.audio_verified_at).to be_nil
  end
end
