require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#format_date" do
    let(:date) { Date.new(2023, 12, 25) }

    context "when date is present" do
      it "formats date with default long format" do
        expect(helper).to receive(:l).with(date, format: :long)
        helper.format_date(date)
      end

      it "formats date with custom format" do
        expect(helper).to receive(:l).with(date, format: :short)
        helper.format_date(date, :short)
      end

      it "returns formatted date string" do
        allow(helper).to receive(:l).and_return("December 25, 2023")
        result = helper.format_date(date)
        expect(result).to eq("December 25, 2023")
      end
    end

    context "when date is not present" do
      it "returns nil for nil date" do
        result = helper.format_date(nil)
        expect(result).to be_nil
      end

      it "returns nil for empty string" do
        result = helper.format_date("")
        expect(result).to be_nil
      end

      it "returns nil for blank date" do
        result = helper.format_date("   ")
        expect(result).to be_nil
      end

      it "does not call l method when date is not present" do
        expect(helper).not_to receive(:l)
        helper.format_date(nil)
      end
    end
  end

  describe "#site_info" do
    it "returns hash with site information" do
      result = helper.site_info

      expect(result).to be_a(Hash)
      expect(result).to have_key(:support_email)
      expect(result).to have_key(:twitter_url)
      expect(result).to have_key(:youtube_url)
    end

    it "returns correct site information values" do
      result = helper.site_info

      expect(result[:support_email]).to eq("")
      expect(result[:twitter_url]).to eq("https://x.com/Moh1Rz2H3?ref")
      expect(result[:youtube_url]).to eq("https://www.youtube.com/@bin-ramzan")
    end

    it "returns consistent data on multiple calls" do
      result1 = helper.site_info
      result2 = helper.site_info

      expect(result1).to eq(result2)
    end
  end

  describe "#format_duration" do
    context "with valid seconds" do
      it "formats seconds correctly for less than a minute" do
        expect(helper.format_duration(45)).to eq("0:45")
      end

      it "formats seconds correctly for exactly one minute" do
        expect(helper.format_duration(60)).to eq("1:00")
      end

      it "formats seconds correctly for more than one minute" do
        expect(helper.format_duration(125)).to eq("2:05")
      end

      it "formats seconds correctly for hours" do
        expect(helper.format_duration(3661)).to eq("61:01")
      end

      it "formats seconds with leading zero for seconds" do
        expect(helper.format_duration(123)).to eq("2:03")
      end

      it "handles zero seconds" do
        expect(helper.format_duration(0)).to eq("0:00")
      end

      it "handles large durations" do
        expect(helper.format_duration(7265)).to eq("121:05")
      end
    end

    context "with invalid or edge case inputs" do
      it "returns '0:00' for nil" do
        expect(helper.format_duration(nil)).to eq("0:00")
      end

      it "returns '0:00' for negative seconds" do
        expect(helper.format_duration(-30)).to eq("0:00")
      end

      it "returns '0:00' for zero" do
        expect(helper.format_duration(0)).to eq("0:00")
      end
    end
  end

  describe "#youtube_embed_url" do
    context "with valid YouTube URLs" do
      it "extracts video ID from youtube.com watch URL" do
        url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        result = helper.youtube_embed_url(url)
        expect(result).to eq("https://www.youtube.com/embed/dQw4w9WgXcQ")
      end

      it "extracts video ID from youtu.be shortened URL" do
        url = "https://youtu.be/dQw4w9WgXcQ"
        result = helper.youtube_embed_url(url)
        expect(result).to eq("https://www.youtube.com/embed/dQw4w9WgXcQ")
      end

      it "works with HTTP (not HTTPS) URLs" do
        url = "http://www.youtube.com/watch?v=dQw4w9WgXcQ"
        result = helper.youtube_embed_url(url)
        expect(result).to eq("https://www.youtube.com/embed/dQw4w9WgXcQ")
      end

      it "works without www prefix" do
        url = "https://youtube.com/watch?v=dQw4w9WgXcQ"
        result = helper.youtube_embed_url(url)
        expect(result).to eq("https://www.youtube.com/embed/dQw4w9WgXcQ")
      end

      it "works without protocol" do
        url = "youtube.com/watch?v=dQw4w9WgXcQ"
        result = helper.youtube_embed_url(url)
        expect(result).to eq("https://www.youtube.com/embed/dQw4w9WgXcQ")
      end

      it "works with additional query parameters" do
        url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30s&list=PLrAXtmRdnEQy"
        result = helper.youtube_embed_url(url)
        expect(result).to eq("https://www.youtube.com/embed/dQw4w9WgXcQ")
      end

      it "handles video IDs with underscores and hyphens" do
        url = "https://www.youtube.com/watch?v=abc_123-XYZ"
        result = helper.youtube_embed_url(url)
        expect(result).to eq("https://www.youtube.com/embed/abc_123-XYZ")
      end
    end

    context "with invalid URLs" do
      it "returns nil for non-YouTube URLs" do
        url = "https://www.google.com"
        result = helper.youtube_embed_url(url)
        expect(result).to be_nil
      end

      it "returns nil for malformed YouTube URLs" do
        url = "https://www.youtube.com/somethingelse"
        result = helper.youtube_embed_url(url)
        expect(result).to be_nil
      end

      it "returns nil for empty string" do
        result = helper.youtube_embed_url("")
        expect(result).to be_nil
      end

      it "returns nil for nil input" do
        result = helper.youtube_embed_url(nil)
        expect(result).to be_nil
      end

      it "returns nil for blank string" do
        result = helper.youtube_embed_url("   ")
        expect(result).to be_nil
      end

      it "returns nil for YouTube URLs without video ID" do
        url = "https://www.youtube.com/watch"
        result = helper.youtube_embed_url(url)
        expect(result).to be_nil
      end
    end
  end
end
