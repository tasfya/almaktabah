# frozen_string_literal: true

require "rails_helper"

RSpec.describe AudioOptimizer do
  let(:dir) { Pathname(Dir.mktmpdir("audio_optimizer")) }
  let(:single) { dir.join("single.mp3") }
  let(:output) { dir.join("out.mp3") }

  before do
    system("ffmpeg", "-v", "error", "-f", "lavfi", "-i", "sine=frequency=440:duration=3",
           "-c:a", "libmp3lame", "-b:a", "64k", single.to_s, exception: true)
  end

  after { FileUtils.rm_rf(dir) }

  def duration(path)
    FFMPEG::Movie.new(path.to_s).duration
  end

  it "optimizes a normal file to the same length" do
    described_class.new(single, output).optimize
    expect(duration(output)).to be_within(0.5).of(duration(single))
  end

  # Some imported files are one MP3 written twice back to back: the header
  # describes one copy while decoding plays both.
  context "when the file is two identical copies of one recording" do
    let(:doubled) { dir.join("doubled.mp3") }

    before { File.binwrite(doubled, File.binread(single) * 2) }

    it "optimizes a single copy" do
      described_class.new(doubled, output).optimize
      expect(duration(output)).to be_within(0.5).of(duration(single))
    end

    it "leaves the input file untouched" do
      expect { described_class.new(doubled, output).optimize }.not_to change { File.binread(doubled) }
    end
  end
end
