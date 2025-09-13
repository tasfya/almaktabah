require 'rails_helper'

RSpec.describe BenefitSerializer, type: :serializer do
  let(:benefit) { create(:benefit) }

  before do
    benefit.content = '<p>Test content</p>'
    benefit.save
  end

  it 'serializes the benefit attributes' do
    serialized = BenefitSerializer.render_as_hash(benefit)
    expect(serialized).to have_key(:id)
    expect(serialized[:title]).to eq(benefit.title)
    expect(serialized[:description]).to eq(benefit.description)
    expect(serialized[:published_at]).to be_present
    expect(serialized[:slug]).to eq(benefit.slug)
    expect(serialized[:content_excerpt]).to eq('Test content')
    expect(serialized[:scholar]).to be_present
  end
end
