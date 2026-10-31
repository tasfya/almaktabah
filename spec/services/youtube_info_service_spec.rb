# frozen_string_literal: true

require "rails_helper"

RSpec.describe YoutubeInfoService do
  let(:video_id) { "dQw4w9WgXcQ" }
  let(:url) { "https://www.youtube.com/watch?v=#{video_id}" }
  let(:oembed_url) { "https://www.youtube.com/oembed?url=#{CGI.escape(url)}&format=json" }
  let(:watch_page) do
    <<~HTML
      <script>var ytInitialPlayerResponse = {"videoDetails":{"lengthSeconds":"3725","viewCount":"1234",
      "shortDescription":"السطر الأول\\nالسطر الثاني"},"microformat":{"publishDate":"2024-03-01"}};</script>
    HTML
  end

  subject(:service) { described_class.new(url: url) }

  describe "#extract_video_id" do
    {
      "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=10" => "dQw4w9WgXcQ",
      "https://youtu.be/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/embed/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/v/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/shorts/dQw4w9WgXcQ" => "dQw4w9WgXcQ",
      "https://www.youtube.com/channel/abc" => nil,
      "https://vimeo.com/123456789" => nil,
      "" => nil
    }.each do |input, expected|
      it "returns #{expected.inspect} for #{input.inspect}" do
        expect(described_class.new(url: input).extract_video_id).to eq(expected)
      end
    end
  end

  it "builds thumbnail and embed URLs from the video id" do
    expect(service.get_thumbnail_url).to eq("https://img.youtube.com/vi/#{video_id}/maxresdefault.jpg")
    expect(service.get_thumbnail_url(quality: "hqdefault")).to eq("https://img.youtube.com/vi/#{video_id}/hqdefault.jpg")
    expect(service.get_embed_url).to eq("https://www.youtube.com/embed/#{video_id}")
  end

  it "returns nil URLs for a non-YouTube link" do
    other = described_class.new(url: "https://example.com/video")

    expect(other.get_thumbnail_url).to be_nil
    expect(other.get_embed_url).to be_nil
  end

  describe "#get_video_info" do
    before do
      stub_request(:get, oembed_url).to_return(
        status: 200, body: { title: "محاضرة", author_name: "الشيخ" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    end

    it "merges oEmbed data with details scraped from the watch page" do
      stub_request(:get, url).to_return(status: 200, body: watch_page)

      expect(service.get_video_info).to eq(
        "title" => "محاضرة",
        "author_name" => "الشيخ",
        "duration" => 3725,
        "view_count" => 1234,
        "upload_date" => "2024-03-01",
        "description" => "السطر الأول\nالسطر الثاني"
      )
    end

    it "keeps escaped quotes in the scraped description" do
      stub_request(:get, url).to_return(status: 200, body: '"shortDescription":"قال \"نعم\" ثم","isLive":false')

      expect(service.get_video_info["description"]).to eq('قال "نعم" ثم')
    end

    it "returns the oEmbed data alone when the watch page fails" do
      stub_request(:get, url).to_return(status: 500)

      expect(service.get_video_info).to eq("title" => "محاضرة", "author_name" => "الشيخ")
    end

    it "keeps oEmbed data when the watch page cannot be fetched" do
      stub_request(:get, url).to_timeout

      expect(service.get_video_info).to eq("title" => "محاضرة", "author_name" => "الشيخ")
    end

    it "decodes a body served without a charset" do
      stub_request(:get, url).to_return(status: 200, body: "<html></html>")
      stub_request(:get, oembed_url).to_return(status: 200, body: { title: "درس" }.to_json.b)

      expect(service.get_video_info["title"]).to eq("درس")
    end

    it "returns nil when oEmbed answers with an error" do
      stub_request(:get, oembed_url).to_return(status: 404, body: "Not Found")

      expect(service.get_video_info).to be_nil
    end

    it "returns nil when oEmbed returns invalid JSON" do
      stub_request(:get, oembed_url).to_return(status: 200, body: "<html>")

      expect(service.get_video_info).to be_nil
    end

    it "makes no request for a non-YouTube URL" do
      expect(described_class.new(url: "https://example.com/watch?v=dQw4w9WgXcQ").get_video_info).to be_nil
      expect(a_request(:any, /youtube/)).not_to have_been_made
    end

    it "makes no request for a YouTube URL without a video id" do
      expect(described_class.new(url: "https://www.youtube.com/channel/abc").get_video_info).to be_nil
      expect(a_request(:any, /youtube/)).not_to have_been_made
    end
  end
end
