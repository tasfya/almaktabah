require 'rails_helper'

RSpec.describe ScholarSerializer, type: :serializer do
  let(:scholar) { create(:scholar, first_name: 'John', last_name: 'Doe', slug: 'john-doe', published_at: Time.current) }

  before do
    scholar.bio = '<p>Test bio</p>'
    scholar.save
  end

  it 'serializes the scholar attributes' do
    serialized = ScholarSerializer.render_as_hash(scholar)
    expect(serialized[:id]).to eq(scholar.id)
    expect(serialized[:first_name]).to eq('John')
    expect(serialized[:last_name]).to eq('Doe')
    expect(serialized[:slug]).to eq('john-doe')
    expect(serialized[:published_at]).to be_present
    expect(serialized[:full_name]).to eq('John Doe')
    expect(serialized[:bio]).to eq('<p>Test bio</p>')
  end
end
