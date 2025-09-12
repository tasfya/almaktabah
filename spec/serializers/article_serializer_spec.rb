require 'rails_helper'

RSpec.describe ArticleSerializer, type: :serializer do
  let(:scholar) { create(:scholar) }
  let(:article) { create(:article, title: 'Test Article', published_at: Time.current, author: scholar) }

  before do
    article.content = '<p>Test content</p>'
    article.save
  end

  it 'serializes the article attributes' do
    serialized = ArticleSerializer.render_as_hash(article)
    expect(serialized).to have_key(:id)
    expect(serialized[:title]).to eq('Test Article')
    expect(serialized[:content]).to eq('<p>Test content</p>')
    expect(serialized[:published_at]).to be_present
    expect(serialized[:author]).to be_present
  end
end
