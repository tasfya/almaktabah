require 'rails_helper'

RSpec.describe BenefitImportJob, type: :job do
  let(:domain) { create(:domain) }
  let(:row_data) do
    {
      'title' => 'Test Benefit',
      'description' => 'A test benefit description',
      'category' => 'Religious',
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
    it 'creates a benefit with valid data' do
      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.to change(Benefit, :count).by(1)

      benefit = Benefit.last
      expect(benefit.title).to eq('Test Benefit')
      expect(benefit.description).to eq('A test benefit description')
      expect(benefit.category).to eq('Religious')
      expect(benefit.published).to be_truthy
    end

    it 'assigns benefit to domain' do
      described_class.new.perform(row_data, domain.id, 2)

      benefit = Benefit.last
      expect(benefit.domains).to include(domain)
    end

    it 'enqueues media download jobs for attachments' do
      expect(MediaDownloadJob).to receive(:perform_now).exactly(3).times

      described_class.new.perform(row_data, domain.id, 2)
    end

    it 'handles missing optional fields gracefully' do
      minimal_data = {
        'title' => 'Minimal Benefit',
        'description' => 'Minimal description' # Required field
      }

      expect {
        described_class.new.perform(minimal_data, domain.id, 2)
      }.to change(Benefit, :count).by(1)

      benefit = Benefit.last
      expect(benefit.title).to eq('Minimal Benefit')
      expect(benefit.published).to be_falsey
      expect(benefit.description).to eq('Minimal description')
    end

    it 'finds or creates benefit by title' do
      existing_benefit = create(:benefit, title: 'Test Benefit')

      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.not_to change(Benefit, :count)

      expect(Benefit.last).to eq(existing_benefit)
    end
  end
end
