require "rails_helper"

RSpec.describe FinalAudioCopier, type: :service do
  let(:audio_path) { Rails.root.join("spec", "files", "audio.mp3") }

  def attach_optimized_audio(record, filename: "optimized.mp3")
    File.open(audio_path, "rb") do |file|
      record.optimized_audio.attach(
        io: file,
        filename: filename,
        content_type: "audio/mpeg"
      )
    end
  end

  def expect_upload_with(key:, filename:)
    expect(ActiveStorage::Blob).to receive(:create_and_upload!)
      .with(hash_including(key: key, filename: filename, service_name: :public_media_aws))
      .and_wrap_original { |method, **args| method.call(**args.merge(service_name: :test)) }
  end

  def latinized_key(record, key)
    described_class.new(record).send(:latinize_audio_key, key)
  end

  describe "#call" do
    it "copies optimized audio into final_audio using the generated key and filename" do
      lesson = create(:lesson)
      attach_optimized_audio(lesson)

      target_key = lesson.generate_optimize_audio_bucket_key
      expected_key = latinized_key(lesson, target_key)
      expect_upload_with(key: expected_key, filename: File.basename(expected_key))

      result = described_class.new(lesson).call

      expect(result).to be true

      lesson.reload
      expect(lesson.final_audio).to be_attached

      expect(lesson.final_audio.blob.key).to eq(expected_key)
      expect(lesson.final_audio.filename.to_s).to eq(File.basename(expected_key))
      expect(lesson.final_audio.blob.service_name).to eq("test")
    end

    it "falls back to the optimized blob key when no generator is available" do
      fatwa = create(:fatwa)
      attach_optimized_audio(fatwa, filename: "fatwa_optimized.mp3")

      source_key = fatwa.optimized_audio.blob.key
      target_key = latinized_key(fatwa, source_key)
      ext = File.extname(target_key)
      base = File.basename(target_key, ext)
      dir = File.dirname(target_key)
      expected_key = dir == "." ? "#{base}-1#{ext}" : "#{dir}/#{base}-1#{ext}"
      expect_upload_with(key: expected_key, filename: File.basename(target_key))

      result = described_class.new(fatwa).call

      expect(result).to be true

      fatwa.reload
      expect(fatwa.final_audio).to be_attached
      expect(fatwa.final_audio.blob.key).to eq(expected_key)
    end

    it "handles Arabic characters in generated keys and filenames" do
      scholar = create(:scholar, full_name: "الشيخ أحمد", first_name: "أحمد", last_name: "العربي")
      series = create(:series, title: "سلسلة التفسير", scholar: scholar)
      lesson = create(:lesson, series: series, title: "الدرس الأول", position: 1)
      attach_optimized_audio(lesson, filename: "arabic_optimized.mp3")

      target_key = lesson.generate_optimize_audio_bucket_key
      expected_key = latinized_key(lesson, target_key)
      expect_upload_with(key: expected_key, filename: File.basename(expected_key))

      result = described_class.new(lesson).call
      expect(result).to be true

      lesson.reload
      expect(lesson.final_audio.blob.key).to eq(expected_key)
      expect(lesson.final_audio.filename.to_s).to eq(File.basename(expected_key))
    end

    it "adds a numeric suffix when the target key already exists" do
      lesson = create(:lesson)
      attach_optimized_audio(lesson)

      target_key = lesson.generate_optimize_audio_bucket_key
      expected_target_key = latinized_key(lesson, target_key)
      File.open(audio_path, "rb") do |file|
        ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: File.basename(expected_target_key),
          content_type: "audio/mpeg",
          key: expected_target_key,
          service_name: :test
        )
      end

      ext = File.extname(expected_target_key)
      base = File.basename(expected_target_key, ext)
      dir = File.dirname(expected_target_key)
      expected_key = dir == "." ? "#{base}-1#{ext}" : "#{dir}/#{base}-1#{ext}"
      expect_upload_with(key: expected_key, filename: File.basename(expected_target_key))

      described_class.new(lesson).call

      lesson.reload
      expect(lesson.final_audio.blob.key).to eq(expected_key)
    end

    it "returns false when optimized audio is missing" do
      record = create(:lesson)

      expect(described_class.new(record).call).to be false
      expect(record.final_audio).not_to be_attached
    end
  end
end
