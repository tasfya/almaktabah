require 'rails_helper'

RSpec.describe SeriesSerializer, type: :serializer do
  let(:series) { create(:series) }

  it 'serializes the series attributes' do
    serialized = SeriesSerializer.render_as_hash(series)
    expect(serialized).to have_key(:id)
    expect(serialized[:title]).to eq(series.title)
    expect(serialized[:description]).to eq(series.description)
    expect(serialized[:published_at]).to be_present
    expect(serialized[:slug]).to eq(series.slug)
    expect(serialized[:explainable_url]).to be_nil
    expect(serialized[:scholar]).to be_present
  end
end
