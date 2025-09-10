require 'rails_helper'

RSpec.describe FatwaImportJob, type: :job do
  let(:domain) { create(:domain) }
  let(:row_data) do
    {
      'title' => 'Test Fatwa',
      'category' => 'Religious',
      'scholar_full_name' => 'Religious',
      'question' => 'What is the ruling on...?',
      'answer' => 'The answer is...',
      'source_url' => 'source_urlsdasdsa',
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
    end

    # it 'assigns fatwa to domain' do
    #   described_class.new.perform(row_data, domain.id, 2)

    #   fatwa = Fatwa.last
    #   expect(fatwa.domains).to include(domain)
    # end
  end
end
