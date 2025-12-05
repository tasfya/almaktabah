require 'rails_helper'

RSpec.describe TypesenseSearchService::SearchHit do
  let(:hit_data) do
    {
      "document" => {
        "id" => "123",
        "title" => "Test Title",
        "description" => "Test description",
        "content_type" => "book",
        "slug" => "test-book",
        "scholar_name" => "Test Scholar",
        "scholar_slug" => "test-scholar",
        "scholar_id" => 456,
        "media_type" => "text",
        "published_at" => 1700000000
      },
      "highlights" => [
        { "field" => "title", "snippet" => "<mark>Test</mark> Title" },
        { "field" => "description", "snippet" => "<mark>Test</mark> description" }
      ],
      "text_match" => 100
    }
  end

  let(:hit) { described_class.new(hit_data, "book") }

  describe '#initialize' do
    it 'stores document data' do
      expect(hit.document).to eq(hit_data["document"])
    end

    it 'stores highlights' do
      expect(hit.highlights).to eq(hit_data["highlights"])
    end

    it 'stores text_match score' do
      expect(hit.text_match).to eq(100)
    end

    it 'stores content_type' do
      expect(hit.content_type).to eq("book")
    end
  end

  describe '#id' do
    it 'returns document id' do
      expect(hit.id).to eq("123")
    end
  end

  describe '#slug' do
    it 'returns slug from document' do
      expect(hit.slug).to eq("test-book")
    end
  end

  describe '#title' do
    it 'returns title from document' do
      expect(hit.title).to eq("Test Title")
    end

    context 'for scholar' do
      let(:scholar_hit_data) do
        {
          "document" => { "id" => "1", "name" => "Scholar Name", "content_type" => "scholar" },
          "highlights" => [],
          "text_match" => 50
        }
      end

      it 'falls back to name field' do
        scholar_hit = described_class.new(scholar_hit_data, "scholar")
        expect(scholar_hit.title).to eq("Scholar Name")
      end
    end
  end

  describe '#highlighted_title' do
    it 'returns highlighted snippet when available' do
      expect(hit.highlighted_title).to eq("<mark>Test</mark> Title")
    end

    it 'falls back to title when no highlight' do
      hit_without_highlight = described_class.new(
        { "document" => { "title" => "Plain Title" }, "highlights" => [] },
        "book"
      )
      expect(hit_without_highlight.highlighted_title).to eq("Plain Title")
    end
  end

  describe '#description' do
    it 'returns description from document' do
      expect(hit.description).to eq("Test description")
    end

    it 'falls back to content_text' do
      hit_with_content = described_class.new(
        { "document" => { "content_text" => "Content text" }, "highlights" => [] },
        "fatwa"
      )
      expect(hit_with_content.description).to eq("Content text")
    end
  end

  describe '#highlighted_description' do
    it 'returns highlighted snippet when available' do
      expect(hit.highlighted_description).to eq("<mark>Test</mark> description")
    end

    it 'falls back to description when no highlight' do
      hit_without_highlight = described_class.new(
        { "document" => { "description" => "Plain desc" }, "highlights" => [] },
        "book"
      )
      expect(hit_without_highlight.highlighted_description).to eq("Plain desc")
    end
  end

  describe '#scholar_name' do
    it 'returns scholar_name from document' do
      expect(hit.scholar_name).to eq("Test Scholar")
    end
  end

  describe '#scholar_slug' do
    it 'returns scholar_slug from document' do
      expect(hit.scholar_slug).to eq("test-scholar")
    end
  end

  describe '#scholar_id' do
    it 'returns scholar_id from document' do
      expect(hit.scholar_id).to eq(456)
    end
  end

  describe '#media_type' do
    it 'returns media_type from document' do
      expect(hit.media_type).to eq("text")
    end
  end

  describe '#published_at' do
    it 'returns Time object from timestamp' do
      expect(hit.published_at).to be_a(Time)
      expect(hit.published_at.to_i).to eq(1700000000)
    end

    it 'returns nil when no published_at' do
      hit_without_date = described_class.new(
        { "document" => {}, "highlights" => [] },
        "book"
      )
      expect(hit_without_date.published_at).to be_nil
    end
  end

  describe '#first_name and #last_name' do
    let(:scholar_hit_data) do
      {
        "document" => {
          "id" => "1",
          "first_name" => "Ahmad",
          "last_name" => "Ibn Taymiyyah",
          "slug" => "ahmad-ibn-taymiyyah"
        },
        "highlights" => []
      }
    end

    it 'returns first_name from document' do
      scholar_hit = described_class.new(scholar_hit_data, "scholar")
      expect(scholar_hit.first_name).to eq("Ahmad")
    end

    it 'returns last_name from document' do
      scholar_hit = described_class.new(scholar_hit_data, "scholar")
      expect(scholar_hit.last_name).to eq("Ibn Taymiyyah")
    end
  end

  describe '#series_title and #series_slug' do
    let(:lesson_hit_data) do
      {
        "document" => {
          "id" => "1",
          "title" => "Lesson 1",
          "series_title" => "Tafsir Series",
          "series_slug" => "tafsir-series",
          "slug" => "1"
        },
        "highlights" => []
      }
    end

    it 'returns series_title from document' do
      lesson_hit = described_class.new(lesson_hit_data, "lesson")
      expect(lesson_hit.series_title).to eq("Tafsir Series")
    end

    it 'returns series_slug from document' do
      lesson_hit = described_class.new(lesson_hit_data, "lesson")
      expect(lesson_hit.series_slug).to eq("tafsir-series")
    end
  end

  describe '#url' do
    it 'returns correct URL for book (Arabic route)' do
      expect(hit.url).to eq("/test-scholar/الكتب/test-book")
    end

    it 'returns correct URL for lecture (Arabic route)' do
      lecture_hit = described_class.new(
        { "document" => { "slug" => "my-lecture", "scholar_slug" => "scholar-name" }, "highlights" => [] },
        "lecture"
      )
      expect(lecture_hit.url).to eq("/scholar-name/المحاضرات/my-lecture")
    end

    it 'returns correct URL for lesson (Arabic route)' do
      lesson_hit = described_class.new(
        { "document" => { "slug" => "1", "series_slug" => "my-series" }, "highlights" => [] },
        "lesson"
      )
      expect(lesson_hit.url).to eq("/الدروس/1")
    end

    it 'returns correct URL for series (Arabic route)' do
      series_hit = described_class.new(
        { "document" => { "slug" => "my-series", "scholar_slug" => "scholar-name" }, "highlights" => [] },
        "series"
      )
      expect(series_hit.url).to eq("/scholar-name/السلاسل/my-series")
    end

    it 'returns correct URL for scholar (Arabic route)' do
      scholar_hit = described_class.new(
        { "document" => { "slug" => "scholar-name" }, "highlights" => [] },
        "scholar"
      )
      expect(scholar_hit.url).to eq("/العلماء/scholar-name")
    end

    it 'returns correct URL for fatwa (Arabic route)' do
      fatwa_hit = described_class.new(
        { "document" => { "slug" => "my-fatwa" }, "highlights" => [] },
        "fatwa"
      )
      expect(fatwa_hit.url).to eq("/الفتاوى/my-fatwa")
    end

    it 'returns correct URL for news (Arabic route)' do
      news_hit = described_class.new(
        { "document" => { "slug" => "my-news" }, "highlights" => [] },
        "news"
      )
      expect(news_hit.url).to eq("/الأخبار/my-news")
    end

    it 'raises ArgumentError for unknown content_type' do
      unknown_hit = described_class.new(
        { "document" => { "slug" => "test" }, "highlights" => [] },
        "unknown"
      )
      expect { unknown_hit.url }.to raise_error(ArgumentError, /Unknown content_type: unknown/)
    end
  end

  describe '#label' do
    it 'returns title for book' do
      expect(hit.label).to eq("Test Title")
    end

    it 'returns series_title for lesson' do
      lesson_hit = described_class.new(
        { "document" => { "title" => "Lesson 1", "series_title" => "Tafsir Series" }, "highlights" => [] },
        "lesson"
      )
      expect(lesson_hit.label).to eq("Tafsir Series")
    end

    it 'returns full name for scholar' do
      scholar_hit = described_class.new(
        { "document" => { "first_name" => "Ahmad", "last_name" => "Ibn Taymiyyah" }, "highlights" => [] },
        "scholar"
      )
      expect(scholar_hit.label).to eq("Ahmad Ibn Taymiyyah")
    end
  end
end
