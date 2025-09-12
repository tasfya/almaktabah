require 'rails_helper'

RSpec.describe NewsSerializer, type: :serializer do
  let(:news) { create(:news, title: 'Test News', published_at: Time.current, slug: 'test-news') }

  before do
    news.content = '<p>Test content</p>'
    news.save
  end

  it 'serializes the news attributes' do
    serialized = NewsSerializer.render_as_hash(news)
    expect(serialized).to have_key(:id)
    expect(serialized[:title]).to eq('Test News')
    expect(serialized[:content_excerpt]).to eq('Test content')
    expect(serialized[:published_at]).to be_present
    expect(serialized[:slug]).to eq('test-news')
  end
end
