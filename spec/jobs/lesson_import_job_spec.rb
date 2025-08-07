require 'rails_helper'

RSpec.describe LessonImportJob, type: :job do
  let(:domain) { create(:domain) }
  let(:row_data) do
    {
      'title' => 'Test Lesson',
      'description' => 'A test lesson description',
      'category' => 'Education',
      'content_type' => 'audio',
      'series_title' => 'Test Series',
      'author_first_name' => 'Ahmed',
      'author_last_name' => 'Al-Scholar',
      'youtube_url' => 'https://youtube.com/watch?v=abc123',
      'position' => '1',
      'published_at' => '2024-01-01 00:00:00',
      'thumbnail_url' => 'https://example.com/thumb.jpg',
      'audio_file_url' => 'https://example.com/audio.mp3',
      'video_file_url' => 'https://example.com/video.mp4'
    }
  end

  before do
    allow(MediaDownloadJob).to receive(:perform_now)
  end

  describe '#perform' do
    it 'creates a lesson with valid data' do
      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.to change(Lesson, :count).by(1)

      lesson = Lesson.unscoped.last
      expect(lesson.title).to eq('Test Lesson')
      expect(lesson.description).to eq('A test lesson description')
      expect(lesson.category).to eq('Education')
      expect(lesson.content_type).to eq('audio')
      expect(lesson.youtube_url).to eq('https://youtube.com/watch?v=abc123')
      expect(lesson.position).to eq(1)
      expect(lesson.published).to be_truthy
    end

    it 'creates or finds a series' do
      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.to change(Series, :count).by(1)

      lesson = Lesson.unscoped.last
      series = Series.last
      expect(lesson.series).to eq(series)
      expect(series.title).to eq('Test Series')
      expect(series.published).to be_truthy
    end

    it 'reuses existing series' do
      existing_series = create(:series, title: 'Test Series')

      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.not_to change(Series, :count)

      lesson = Lesson.unscoped.last
      expect(lesson.series).to eq(existing_series)
    end

    it 'assigns lesson to domain' do
      described_class.new.perform(row_data, domain.id, 2)

      lesson = Lesson.unscoped.last
      expect(lesson.domains).to include(domain)
    end

    it 'enqueues media download jobs for attachments' do
      expect(MediaDownloadJob).to receive(:perform_now).exactly(3).times

      described_class.new.perform(row_data, domain.id, 2)
    end

    it 'handles missing optional fields gracefully' do
      minimal_data = {
        'title' => 'Minimal Lesson',
        'series_title' => 'Default Series',
        'author_first_name' => 'Test',
        'author_last_name' => 'Author'
      }

      expect {
        described_class.new.perform(minimal_data, domain.id, 2)
      }.to change(Lesson, :count).by(1)

      lesson = Lesson.unscoped.last
      expect(lesson.title).to eq('Minimal Lesson')
      expect(lesson.published).to be_falsey
      expect(lesson.content_type).to eq('audio') # Should default to audio
    end

    it 'raises error when scholar information is missing' do
      minimal_data = {
        'title' => 'Lesson Without Scholar',
        'series_title' => 'Some Series'
      }

      expect {
        described_class.new.perform(minimal_data, domain.id, 2)
      }.to raise_error(ArgumentError, "Scholar information (author_first_name and/or author_last_name) is required")
    end

    it 'defaults content_type to audio when not provided' do
      data_without_content_type = row_data.except('content_type')

      described_class.new.perform(data_without_content_type, domain.id, 2)

      lesson = Lesson.unscoped.last
      expect(lesson.content_type).to eq('audio')
    end
  end
end
