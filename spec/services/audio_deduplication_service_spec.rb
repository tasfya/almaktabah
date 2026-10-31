# frozen_string_literal: true

require "rails_helper"

# Runs real ffmpeg (installed in CI) on files built from spec/files/audio.mp3
# (58s): the clip played twice, and the clip followed by 58s of silence.
RSpec.describe AudioDeduplicationService do
  subject(:service) { described_class.new(min_duration: 20) }

  let(:source) { Rails.root.join("spec/files/audio.mp3").to_s }
  let(:work_dir) { Rails.root.join("tmp/spec_audio_dedup/#{SecureRandom.hex(4)}").to_s }

  before { FileUtils.mkdir_p(work_dir) }
  after { FileUtils.rm_rf(work_dir) }

  def ffmpeg!(*args)
    system("ffmpeg", "-y", "-loglevel", "error", *args, exception: true)
  end

  def doubled(path = File.join(work_dir, "doubled.mp3"))
    ffmpeg!("-i", "concat:#{source}|#{source}", "-c", "copy", path)
    path
  end

  def with_silence(path = File.join(work_dir, "with_silence.mp3"))
    ffmpeg!("-i", source, "-f", "lavfi", "-t", "58", "-i", "anullsrc=r=44100:cl=stereo",
            "-filter_complex", "[0:a][1:a]concat=n=2:v=0:a=1", "-b:a", "64k", path)
    path
  end

  def duration(path)
    FFMPEG::Movie.new(path).duration
  end

  describe "#analyze_file" do
    it "flags a recording that repeats itself" do
      result = service.analyze_file(doubled)

      expect(result).to include(is_duplicate: true, repeat_factor: 2)
      expect(result[:duration]).to be_within(1).of(116)
      expect(result[:clean_duration]).to be_within(0.5).of(result[:duration] / 2)
    end

    it "does not flag a recording whose halves differ" do
      expect(service.analyze_file(with_silence)).to include(is_duplicate: false)
    end

    it "skips files shorter than min_duration" do
      expect(described_class.new.analyze_file(source)).to include(is_duplicate: false, reason: "too_short")
    end
  end

  describe "#fix_file!" do
    it "trims a duplicated file in place and keeps a backup" do
      path = doubled
      original_size = File.size(path)

      result = service.fix_file!(path)

      expect(result).to include(fixed: true, repeat_factor: 2, backup_path: "#{path}.backup")
      expect(duration(path)).to be_within(1).of(58)
      expect(File.size("#{path}.backup")).to eq(original_size)
    end

    it "can skip the backup" do
      path = doubled

      expect(service.fix_file!(path, backup: false)).to include(fixed: true, backup_path: nil)
      expect(File.exist?("#{path}.backup")).to be(false)
    end

    it "leaves a file that is not duplicated untouched" do
      path = with_silence

      expect { expect(service.fix_file!(path)).to eq(fixed: false, reason: "not_duplicate") }
        .not_to(change { File.size(path) })
    end
  end

  describe "folders" do
    let(:input) { File.join(work_dir, "in") }
    let(:output_dir) { File.join(work_dir, "out") }

    before do
      FileUtils.mkdir_p(File.join(input, "series"))
      doubled(File.join(input, "series", "doubled.mp3"))
      with_silence(File.join(input, "clean.mp3"))
      File.write(File.join(input, "broken.mp3"), "not audio")
      File.write(File.join(input, "notes.txt"), "ignored")
    end

    it "#analyze_folder reports duplicates without changing anything" do
      result = nil

      expect { result = service.analyze_folder(input) }.to output(/\[DUPLICATE\] doubled\.mp3/).to_stdout
      expect(result).to include(total_files: 3, analyzed: 3, duplicates_found: 1)
      expect(result[:duplicate_files]).to contain_exactly(a_hash_including(path: File.join(input, "series", "doubled.mp3"), repeat_factor: 2))
      # ffmpeg reads an unreadable file as zero-length, so it counts as too short, not as an error.
      expect(result[:errors]).to be_empty
      expect(duration(File.join(input, "series", "doubled.mp3"))).to be_within(1).of(116)
    end

    it "#process_folder writes trimmed and copied files under the same relative paths" do
      result = nil

      expect { result = service.process_folder(input, output_dir) }.to output.to_stdout
      expect(result).to include(total_files: 3, processed: 3, duplicates_found: 1)
      expect(duration(File.join(output_dir, "series", "doubled.mp3"))).to be_within(1).of(58)
      expect(FileUtils.identical?(File.join(input, "clean.mp3"), File.join(output_dir, "clean.mp3"))).to be(true)
      expect(File.read(File.join(output_dir, "broken.mp3"))).to eq("not audio")
    end

    it "raises for a missing folder" do
      expect { service.analyze_folder(File.join(work_dir, "missing")) }
        .to raise_error(AudioDeduplicationService::ProcessingError, /Folder does not exist/)
    end
  end
end
