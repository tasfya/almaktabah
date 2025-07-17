require 'rails_helper'

RSpec.describe LecturesImportJob, type: :job do
  let(:domain) { create(:domain) }
  let(:row_data) do
    {
      'title' => 'Test Lecture',
      'description' => 'A test lecture description',
      'category' => 'Religious',
      'youtube_url' => 'https://youtube.com/watch?v=abc123',
      'published_at' => '2024-01-01 00:00:00',
      'thumbnail_url' => 'https://example.com/thumb.jpg',
      'audio_file_url' => 'https://example.com/audio.mp3',
      'video_file_url' => 'https://example.com/video.mp4'
    }
  end

  describe '#perform' do
    it 'creates a lecture with valid data' do
      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.to change(Lecture, :count).by(1)

      lecture = Lecture.last
      expect(lecture.title).to eq('Test Lecture')
      expect(lecture.description).to eq('A test lecture description')
      expect(lecture.category).to eq('Religious')
      expect(lecture.youtube_url).to eq('https://youtube.com/watch?v=abc123')
      expect(lecture.published).to be_truthy
    end

    it 'assigns lecture to domain' do
      described_class.new.perform(row_data, domain.id, 2)

      lecture = Lecture.last
      expect(lecture.domains).to include(domain)
    end

    it 'enqueues media download jobs for attachments' do
      expect(MediaDownloadJob).to receive(:perform_later).exactly(3).times

      described_class.new.perform(row_data, domain.id, 2)
    end

    it 'handles missing optional fields gracefully' do
      minimal_data = {
        'title' => 'Minimal Lecture'
      }

      expect {
        described_class.new.perform(minimal_data, domain.id, 2)
      }.to change(Lecture, :count).by(1)

      lecture = Lecture.last
      expect(lecture.title).to eq('Minimal Lecture')
      expect(lecture.published).to be_falsey
    end

    it 'finds or creates lecture by title' do
      existing_lecture = create(:lecture, title: 'Test Lecture')

      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.not_to change(Lecture, :count)

      expect(Lecture.last).to eq(existing_lecture)
    end
  end
end
