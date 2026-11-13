require "rails_helper"

RSpec.describe TelegramImport::VideoId do
  [
    "https://youtu.be/VlwiR0IJt7M",
    "https://www.youtube.com/watch?v=VlwiR0IJt7M&t=3",
    "https://www.youtube.com/live/VlwiR0IJt7M?si=x",
    "https://www.youtube.com/embed/VlwiR0IJt7M",
    "https://www.youtube.com/shorts/VlwiR0IJt7M",
    "`https://youtu.be/VlwiR0IJt7M"
  ].each do |url|
    it("extracts the id from #{url}") { expect(described_class.extract(url)).to eq("VlwiR0IJt7M") }
  end

  it "returns nil for a non-YouTube URL" do
    expect(described_class.extract("https://docs.google.com/forms/d/e/x/viewform")).to be_nil
  end

  it "returns nil for nil" do
    expect(described_class.extract(nil)).to be_nil
  end

  it "builds the watch URL" do
    expect(described_class.watch_url("VlwiR0IJt7M")).to eq("https://www.youtube.com/watch?v=VlwiR0IJt7M")
  end
end
