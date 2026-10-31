# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediaDownloadJob, type: :job do
  let(:lecture) { create(:lecture, thumbnail: nil) }
  let(:url) { "https://cdn.example.com/media/cover.jpg" }

  it "downloads the file and attaches it under the URL's file name" do
    stub_request(:get, url).to_return(status: 200, body: Rails.root.join("spec/files/thumbnail.jpg").binread)

    described_class.perform_now(lecture, :thumbnail, url, "image/jpeg")

    lecture.reload
    expect(lecture.thumbnail.filename.to_s).to eq("cover.jpg")
    expect(lecture.thumbnail.content_type).to eq("image/jpeg")
    expect(lecture.thumbnail.download).to eq(Rails.root.join("spec/files/thumbnail.jpg").binread)
  end

  it "leaves the query string out of the file name" do
    signed_url = "#{url}?sig=abc.def"
    stub_request(:get, signed_url).to_return(status: 200, body: "jpeg-bytes")

    described_class.perform_now(lecture, :thumbnail, signed_url, "image/jpeg")

    expect(lecture.reload.thumbnail.filename.to_s).to eq("cover.jpg")
  end

  it "follows redirects" do
    stub_request(:get, url).to_return(status: 302, headers: { "Location" => "https://cdn2.example.com/cover.jpg" })
    stub_request(:get, "https://cdn2.example.com/cover.jpg").to_return(status: 200, body: "jpeg-bytes")

    described_class.perform_now(lecture, "thumbnail", url, "image/jpeg")

    expect(lecture.reload.thumbnail.download).to eq("jpeg-bytes")
  end

  it "raises and attaches nothing when the server answers with an error" do
    stub_request(:get, url).to_return(status: 404)

    expect { described_class.perform_now(lecture, :thumbnail, url, "image/jpeg") }
      .to raise_error(RuntimeError, /Download failed: 404/)
    expect(lecture.reload.thumbnail).not_to be_attached
  end

  it "raises on a timeout" do
    stub_request(:get, url).to_timeout

    expect { described_class.perform_now(lecture, :thumbnail, url, "image/jpeg") }.to raise_error(Net::OpenTimeout)
  end

  it "does nothing for a blank URL" do
    described_class.perform_now(lecture, :thumbnail, "", "image/jpeg")

    expect(lecture.reload.thumbnail).not_to be_attached
  end
end
