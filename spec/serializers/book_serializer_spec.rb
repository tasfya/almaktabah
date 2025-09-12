require 'rails_helper'

RSpec.describe BookSerializer, type: :serializer do
  let(:book) { create(:book, title: 'Test Book', description: 'Description', published_at: Time.current, downloads: 100, slug: 'test-book') }

  it 'serializes the book attributes' do
    serialized = BookSerializer.render_as_hash(book)
    expect(serialized[:id]).to eq(book.id)
    expect(serialized[:title]).to eq('Test Book')
    expect(serialized[:description]).to eq('Description')
    expect(serialized[:published_at]).to be_present
    expect(serialized[:downloads]).to eq(100)
    expect(serialized[:slug]).to eq('test-book')
    expect(serialized[:author]).to be_present
    expect(serialized[:file_url]).to be_present
  end

  # Test for file attachment would go here if we had test files
end
