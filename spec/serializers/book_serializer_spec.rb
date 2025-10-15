require 'rails_helper'

RSpec.describe BookSerializer, type: :serializer do
  let(:book) { create(:book) }

  it 'serializes the book attributes' do
    serialized = BookSerializer.render_as_hash(book)
    expect(serialized[:id]).to eq(book.id)
    expect(serialized[:title]).to eq(book.title)
    expect(serialized[:description]).to eq(book.description)
    expect(serialized[:published_at]).to be_present
    expect(serialized[:downloads]).to eq(book.downloads)
    expect(serialized[:slug]).to eq(book.slug)
    expect(serialized[:scholar]).to be_present
    expect(serialized[:file_url]).to be_present
  end

  # Test for file attachment would go here if we had test files
end
