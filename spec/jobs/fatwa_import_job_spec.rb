require 'rails_helper'

RSpec.describe FatwaImportJob, type: :job do
  let(:domain) { create(:domain) }
  let(:row_data) do
    {
      'title' => 'Test Fatwa',
      'category' => 'Religious',
      'question' => 'What is the ruling on...?',
      'answer' => 'The answer is...',
      'published_at' => '2024-01-01 00:00:00'
    }
  end

  describe '#perform' do
    it 'creates a fatwa with valid data' do
      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.to change(Fatwa, :count).by(1)

      fatwa = Fatwa.last
      expect(fatwa.title).to eq('Test Fatwa')
      expect(fatwa.category).to eq('Religious')
      expect(fatwa.question.to_s).to include('What is the ruling on...?')
      expect(fatwa.answer.to_s).to include('The answer is...')
      expect(fatwa.published).to be_truthy
    end

    it 'assigns fatwa to domain' do
      described_class.new.perform(row_data, domain.id, 2)

      fatwa = Fatwa.last
      expect(fatwa.domains).to include(domain)
    end

    it 'handles missing optional fields gracefully' do
      minimal_data = {
        'title' => 'Minimal Fatwa',
        'category' => 'Religious'
      }

      expect {
        described_class.new.perform(minimal_data, domain.id, 2)
      }.to change(Fatwa, :count).by(1)

      fatwa = Fatwa.last
      expect(fatwa.title).to eq('Minimal Fatwa')
      expect(fatwa.published).to be_falsey
      expect(fatwa.question.to_s).to be_blank
    end

    it 'finds or creates fatwa by title and category' do
      existing_fatwa = create(:fatwa, title: 'Test Fatwa', category: 'Religious')

      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.not_to change(Fatwa, :count)

      expect(Fatwa.last).to eq(existing_fatwa)
    end
  end
end
