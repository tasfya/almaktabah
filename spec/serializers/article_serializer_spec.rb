require 'rails_helper'

RSpec.describe ArticleSerializer, type: :serializer do
  let(:article) { create(:article) }

  before do
    article.content = '<p>Test content</p>'
    article.save
  end

  it 'serializes the article attributes' do
    serialized = ArticleSerializer.render_as_hash(article)
    expect(serialized).to have_key(:id)
    expect(serialized[:title]).to eq(article.title)
    expect(serialized[:content]).to include('Test content')
    expect(serialized[:published_at]).to be_present
    expect(serialized[:scholar]).to be_present
  end
end
