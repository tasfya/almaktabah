require 'rails_helper'

RSpec.describe Benefit, type: :model do
    subject(:benefit) { build(:benefit) }
  describe "methods" do
    describe "media_type" do
      context "when video is attached" do
        before { benefit.video.attach(io: StringIO.new("video content"), filename: "video.mp4", content_type: "video/mp4") }

        it "returns the video type" do
          expect(benefit.media_type).to eq(I18n.t("common.video"))
        end
      end

      context "when audio is attached" do
        before { benefit.audio.attach(io: StringIO.new("audio content"), filename: "audio.mp3", content_type: "audio/mpeg") }

        it "returns the audio type" do
          expect(benefit.media_type).to eq(I18n.t("common.audio"))
        end
      end

      context "when no media is attached" do
        before do
          benefit.video.purge
          benefit.audio.purge
        end
        it "returns nil" do
          expect(benefit.media_type).to be_nil
        end
      end
    end
  end
end
