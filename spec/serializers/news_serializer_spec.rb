require 'rails_helper'

RSpec.describe NewsSerializer, type: :serializer do
  let(:news) { create(:news) }

  before do
    news.content = '<p>Test content</p>'
    news.save
  end

  it 'serializes the news attributes' do
    serialized = NewsSerializer.render_as_hash(news)
    expect(serialized).to have_key(:id)
    expect(serialized[:title]).to eq(news.title)
    expect(serialized[:content_excerpt]).to eq('Test content')
    expect(serialized[:published_at]).to be_present
    expect(serialized[:slug]).to eq(news.slug)
  end
end
