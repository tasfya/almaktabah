# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypesenseSearch::SearchHit do
  let(:hit_data) do
    {
      "document" => {
        "id" => "123",
        "title" => "Test Title",
        "description" => "Test description",
        "slug" => "test-book",
        "scholar_name" => "Test Scholar",
        "scholar_slug" => "test-scholar",
        "media_type" => "text"
      },
      "highlights" => [
        { "field" => "title", "snippet" => "<mark>Test</mark> Title" },
        { "field" => "description", "snippet" => "<mark>Test</mark> description" }
      ]
    }
  end

  let(:hit) { described_class.new(hit_data, "book") }

  describe "#initialize" do
    it "stores highlights" do
      expect(hit.highlights).to eq(hit_data["highlights"])
    end

    it "stores content_type" do
      expect(hit.content_type).to eq("book")
    end
  end

  describe "#id" do
    it "returns document id" do
      expect(hit.id).to eq("123")
    end
  end

  describe "#slug" do
    it "returns slug from document" do
      expect(hit.slug).to eq("test-book")
    end
  end

  describe "#title" do
    it "returns title from document" do
      expect(hit.title).to eq("Test Title")
    end

    context "when title is absent but name exists" do
      let(:name_hit_data) do
        {
          "document" => { "id" => "1", "name" => "Some Name" },
          "highlights" => []
        }
      end

      it "falls back to name field" do
        name_hit = described_class.new(name_hit_data, "book")
        expect(name_hit.title).to eq("Some Name")
      end
    end
  end

  describe "#highlighted_title" do
    it "returns highlighted snippet when available" do
      expect(hit.highlighted_title).to eq("<mark>Test</mark> Title")
    end

    it "falls back to title when no highlight" do
      hit_without_highlight = described_class.new(
        { "document" => { "title" => "Plain Title" }, "highlights" => [] },
        "book"
      )
      expect(hit_without_highlight.highlighted_title).to eq("Plain Title")
    end
  end

  describe "#description" do
    it "returns description from document" do
      expect(hit.description).to eq("Test description")
    end

    it "falls back to content_text" do
      hit_with_content = described_class.new(
        { "document" => { "content_text" => "Content text" }, "highlights" => [] },
        "fatwa"
      )
      expect(hit_with_content.description).to eq("Content text")
    end
  end

  describe "#highlighted_description" do
    it "returns highlighted snippet when available" do
      expect(hit.highlighted_description).to eq("<mark>Test</mark> description")
    end

    it "falls back to description when no highlight" do
      hit_without_highlight = described_class.new(
        { "document" => { "description" => "Plain desc" }, "highlights" => [] },
        "book"
      )
      expect(hit_without_highlight.highlighted_description).to eq("Plain desc")
    end
  end

  describe "#scholar_name" do
    it "returns scholar_name from document" do
      expect(hit.scholar_name).to eq("Test Scholar")
    end
  end

  describe "#scholar_slug" do
    it "returns scholar_slug from document" do
      expect(hit.scholar_slug).to eq("test-scholar")
    end
  end

  describe "#media_type" do
    it "returns media_type from document" do
      expect(hit.media_type).to eq("text")
    end
  end

  describe "#url" do
    it "returns url from document" do
      hit_with_url = described_class.new(
        { "document" => { "url" => "/test-scholar/الكتب/test-book" }, "highlights" => [] },
        "book"
      )
      expect(hit_with_url.url).to eq("/test-scholar/الكتب/test-book")
    end
  end

  describe "media accessors" do
    let(:media_hit_data) do
      {
        "document" => {
          "id" => "1",
          "thumbnail_url" => "https://example.com/thumb.jpg",
          "audio_url" => "https://example.com/audio.mp3",
          "video_url" => "https://example.com/video.mp4",
          "duration" => 3600,
          "kind" => "khutba",
          "lesson_count" => 10,
          "read_time" => 5
        },
        "highlights" => []
      }
    end

    let(:media_hit) { described_class.new(media_hit_data, "lecture") }

    it "returns thumbnail_url" do
      expect(media_hit.thumbnail_url).to eq("https://example.com/thumb.jpg")
    end

    it "returns audio_url" do
      expect(media_hit.audio_url).to eq("https://example.com/audio.mp3")
    end

    it "returns video_url" do
      expect(media_hit.video_url).to eq("https://example.com/video.mp4")
    end

    it "returns duration" do
      expect(media_hit.duration).to eq(3600)
    end

    it "returns kind" do
      expect(media_hit.kind).to eq("khutba")
    end

    it "returns lesson_count" do
      expect(media_hit.lesson_count).to eq(10)
    end

    it "returns read_time" do
      expect(media_hit.read_time).to eq(5)
    end
  end
end
