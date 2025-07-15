require 'rails_helper'

RSpec.describe UnifiedImporter, type: :service do
  let(:test_file_path) { Rails.root.join('spec', 'fixtures', 'unified_test.xlsx') }

  before do
    allow_any_instance_of(BaseImporter).to receive(:download_and_attach_file)
    workbook = WriteXLSX.new(test_file_path.to_s)
    youtube_url = Faker::Internet.url(host: "youtube.com", path: "/watch?v=#{Faker::Alphanumeric.alpha(number: 11)}")
    image_url = Faker::Internet.url(host: "example.com", path: "/files/#{Faker::File.file_name(ext: "png")}")
    audio_url = Faker::Internet.url(host: "example.com", path: "/files/#{Faker::File.file_name(ext: "mp3")}")
    video_url = Faker::Internet.url(host: "example.com", path: "/files/#{Faker::File.file_name(ext: "mp4")}")

    # Books sheet
    books_sheet = workbook.add_worksheet("Books")
    book_headers = [ "title", "description", "category", "author_first_name", "author_last_name", "pages", "published_at" ]
    book_headers.each_with_index { |header, index| books_sheet.write(0, index, header) }
    books_sheet.write(1, 0, Faker::Book.title)
    books_sheet.write(1, 1, Faker::Lorem.paragraph(sentence_count: 2))
    books_sheet.write(1, 2, Faker::Book.genre)
    books_sheet.write(1, 3, Faker::Name.first_name)
    books_sheet.write(1, 4, Faker::Name.last_name)
    books_sheet.write(1, 5, Faker::Number.between(from: 50, to: 500))
    books_sheet.write(1, 6, Faker::Time.between(from: 1.year.ago, to: Time.now).strftime("%Y-%m-%d %H:%M:%S"))

    # Benefits sheet
    benefits_sheet = workbook.add_worksheet("Benefits")
    benefit_headers = [ "title", "description", "category", "thumbnail_url", "audio_file_url", "video_file_url", "published_at"  ]
    benefit_headers.each_with_index { |header, index| benefits_sheet.write(0, index, header) }
    benefits_sheet.write(1, 0, Faker::Lorem.sentence(word_count: 4))
    benefits_sheet.write(1, 1, Faker::Lorem.paragraph(sentence_count: 3))
    benefits_sheet.write(1, 2, Faker::ProgrammingLanguage.name)
    benefits_sheet.write(1, 4, image_url)
    benefits_sheet.write(1, 5, audio_url)
    benefits_sheet.write(1, 6, video_url)
    benefits_sheet.write(1, 7, Faker::Time.between(from: 1.year.ago, to: Time.now).strftime("%Y-%m-%d %H:%M:%S"))

    # Lectures sheet
    lectures_sheet = workbook.add_worksheet("Lectures")
    lecture_headers = [ "title", "description", "category", "youtube_url", "thumbnail_url", "audio_file_url", "video_file_url", "published_at"  ]
    lecture_headers.each_with_index { |header, index| lectures_sheet.write(0, index, header) }
    lectures_sheet.write(1, 0, Faker::Lorem.sentence(word_count: 5))
    lectures_sheet.write(1, 1, Faker::Lorem.paragraph(sentence_count: 2))
    lectures_sheet.write(1, 2, Faker::ProgrammingLanguage.name)
    lectures_sheet.write(1, 3, youtube_url)
    lectures_sheet.write(1, 4, image_url)
    lectures_sheet.write(1, 5, audio_url)
    lectures_sheet.write(1, 6, video_url)
    lectures_sheet.write(1, 7, Faker::Time.between(from: 1.year.ago, to: Time.now).strftime("%Y-%m-%d %H:%M:%S"))

    # Lessons sheet
    lessons_sheet = workbook.add_worksheet("Lessons")
    lesson_headers = [ "title", "description", "category", "series_title", "youtube_url", "position", "thumbnail_url", "audio_file_url", "video_file_url", "published_at"  ]
    lesson_headers.each_with_index { |header, index| lessons_sheet.write(0, index, header) }
    lessons_sheet.write(1, 0, Faker::Lorem.sentence(word_count: 4))
    lessons_sheet.write(1, 1, Faker::Lorem.paragraph(sentence_count: 2))
    lessons_sheet.write(1, 2, Faker::ProgrammingLanguage.name)
    lessons_sheet.write(1, 3, Faker::Lorem.words(number: 2).join(' ').titleize)
    lessons_sheet.write(1, 4, youtube_url)
    lessons_sheet.write(1, 5, Faker::Number.between(from: 1, to: 10))
    lessons_sheet.write(1, 6, image_url)
    lessons_sheet.write(1, 7, audio_url)
    lessons_sheet.write(1, 8, video_url)
    lessons_sheet.write(1, 9, Faker::Time.between(from: 1.year.ago, to: Time.now).strftime("%Y-%m-%d %H:%M:%S"))

    # Fatwas sheet
    fatwas_sheet = workbook.add_worksheet("Fatwas")
    fatwa_headers = [ "title", "category", "question", "answer", "published_at" ]
    fatwa_headers.each_with_index { |header, index| fatwas_sheet.write(0, index, header) }
    fatwas_sheet.write(1, 0, Faker::Lorem.sentence(word_count: 3))
    fatwas_sheet.write(1, 1, Faker::Lorem.word.capitalize)
    fatwas_sheet.write(1, 2, Faker::Lorem.question)
    fatwas_sheet.write(1, 3, Faker::Lorem.paragraph(sentence_count: 3))
    fatwas_sheet.write(1, 4, Faker::Time.between(from: 1.year.ago, to: Time.now).strftime("%Y-%m-%d %H:%M:%S"))

    workbook.close
  end

  after do
    File.delete(test_file_path) if File.exist?(test_file_path)
  end

  describe '#initialize' do
    it 'initializes with file path' do
      importer = UnifiedImporter.new(test_file_path)
      expect(importer.file_path).to eq(test_file_path)
      expect(importer.results).to be_empty
    end
  end

  describe '#import_all' do
    it 'imports all content types' do
      importer = UnifiedImporter.new(test_file_path)
      expect {
        importer.import_all
      }.to change(Book, :count).by(1)
       .and change(Benefit, :count).by(1)
       .and change(Lecture, :count).by(1)
       .and change(Lesson, :count).by(1)
       .and change(Fatwa, :count).by(1)

      results = importer.results
      expect(results.keys).to contain_exactly(:books, :lectures, :lessons, :benefits, :fatwas)

      # Check that each import was successful
      results.each do |content_type, summary|
        expect(summary[:success_count]).to eq(1)
        expect(summary[:error_count]).to eq(0)
      end
    end
  end

  describe 'individual import methods' do
    let(:importer) { UnifiedImporter.new(test_file_path) }

    it 'imports books only' do
      expect {
        importer.import_books
      }.to change(Book, :count).by(1)
       .and change(Benefit, :count).by(0)

      expect(importer.results[:books][:success_count]).to eq(1)
    end

    it 'imports benefits only' do
      expect {
        importer.import_benefits
      }.to change(Benefit, :count).by(1)
       .and change(Book, :count).by(0)

      expect(importer.results[:benefits][:success_count]).to eq(1)
    end

    it 'imports lectures only' do
      expect {
        importer.import_lectures
      }.to change(Lecture, :count).by(1)
       .and change(Book, :count).by(0)

      expect(importer.results[:lectures][:success_count]).to eq(1)
    end

    it 'imports lessons only' do
      expect {
        importer.import_lessons
      }.to change(Lesson, :count).by(1)
       .and change(Book, :count).by(0)

      expect(importer.results[:lessons][:success_count]).to eq(1)
    end

    it 'imports fatwas only' do
      expect {
        importer.import_fatwas
      }.to change(Fatwa, :count).by(1)
       .and change(Book, :count).by(0)

      expect(importer.results[:fatwas][:success_count]).to eq(1)
    end
  end

  describe 'custom sheet names' do
    before do
      # Create file with custom sheet names
      workbook = WriteXLSX.new(test_file_path.to_s)

      custom_sheet = workbook.add_worksheet("CustomBooks")
      headers = [ "title", "description", "category", "author_first_name", "author_last_name", "published_at" ]
      headers.each_with_index { |header, index| custom_sheet.write(0, index, header) }
      custom_sheet.write(1, 0, Faker::Book.title)
      custom_sheet.write(1, 1, Faker::Lorem.paragraph(sentence_count: 2))
      custom_sheet.write(1, 2, Faker::Book.genre)
      custom_sheet.write(1, 3, Faker::Name.first_name)
      custom_sheet.write(1, 4, Faker::Name.last_name)
      custom_sheet.write(1, 5, Faker::Time.between(from: 1.year.ago, to: Time.now).strftime("%Y-%m-%d %H:%M:%S"))

      workbook.close
    end
  end
end
