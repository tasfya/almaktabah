require 'rails_helper'

RSpec.describe ScholarSerializer, type: :serializer do
  let(:scholar) { create(:scholar) }

  before do
    scholar.bio = '<p>Test bio</p>'
    scholar.save
  end

  it 'serializes the scholar attributes' do
    serialized = ScholarSerializer.render_as_hash(scholar)
    expect(serialized[:id]).to eq(scholar.id)
    expect(serialized[:first_name]).to eq(scholar.first_name)
    expect(serialized[:last_name]).to eq(scholar.last_name)
    expect(serialized[:slug]).to eq(scholar.slug)
    expect(serialized[:published_at]).to be_present
    expect(serialized[:full_name]).to eq(scholar.name)
    expect(serialized[:bio]).to include('Test bio')
  end
end
