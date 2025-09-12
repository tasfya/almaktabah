require 'rails_helper'

RSpec.describe SeriesSerializer, type: :serializer do
  let(:scholar) { create(:scholar) }
  let(:series) { create(:series, scholar: scholar, title: 'Test Series', description: 'Description', published_at: Time.current, slug: 'test-series') }

  it 'serializes the series attributes' do
    serialized = SeriesSerializer.render_as_hash(series)
    expect(serialized).to have_key(:id)
    expect(serialized[:title]).to eq('Test Series')
    expect(serialized[:description]).to eq('Description')
    expect(serialized[:published_at]).to be_present
    expect(serialized[:slug]).to eq('test-series')
    expect(serialized[:explainable_url]).to be_nil
    expect(serialized[:scholar]).to be_present
  end
end
