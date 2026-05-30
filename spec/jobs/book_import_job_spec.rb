require 'rails_helper'

RSpec.describe BookImportJob, type: :job do
  let(:domain) { create(:domain) }
  let(:row_data) do
    {
      'title' => 'Test Book',
      'description' => 'A test book description',
      'category' => 'Islamic Studies',
      'scholar_full_name' => 'John Doe',
      'pages' => '150',
      'published_at' => '2024-01-01 00:00:00',
      'file_url' => 'https://example.com/book.pdf',
      'cover_image_url' => 'https://example.com/cover.jpg'
    }
  end

  before do
    allow(MediaDownloadJob).to receive(:perform_now)
  end

  describe '#perform' do
    it 'creates a book with valid data' do
      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.to change(Book, :count).by(1)

      book = Book.last
      expect(book.title).to eq('Test Book')
      expect(book.description).to eq('A test book description')
      expect(book.category).to eq('Islamic Studies')
      expect(book.pages).to eq(150)
      expect(book.published).to be_truthy
      expect(book.scholar.full_name).to eq('John Doe')
    end

    it 'creates an author if none exists' do
      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.to change(Scholar, :count).by(1)

      scholar = Scholar.last
      expect(scholar.full_name).to eq('John Doe')
      expect(scholar.published).to be_truthy
    end

    it 'reuses existing author' do
      existing_author = create(:scholar, full_name: 'John Doe')

      expect {
        described_class.new.perform(row_data, domain.id, 2)
      }.not_to change(Scholar, :count)

      book = Book.last
      expect(book.scholar).to eq(existing_author)
    end

    it 'assigns book to domain' do
      described_class.new.perform(row_data, domain.id, 2)

      book = Book.last
      expect(book.domains).to include(domain)
    end

    it 'enqueues media download jobs for attachments' do
      expect(MediaDownloadJob).to receive(:perform_now).twice

      described_class.new.perform(row_data, domain.id, 2)
    end

    it 'handles missing optional fields gracefully' do
      minimal_data = {
        'title' => 'Minimal Book',
        'scholar_full_name' => 'Jane Smith'
      }

      expect {
        described_class.new.perform(minimal_data, domain.id, 2)
      }.to change(Book, :count).by(1)

      book = Book.last
      expect(book.title).to eq('Minimal Book')
      expect(book.published).to be_falsey
      expect(book.pages).to be_nil
    end

    it 'raises error when author information is missing' do
      empty_author_data = {
        'title' => 'Book Without Author'
      }

      expect {
        described_class.new.perform(empty_author_data, domain.id, 2)
      }.to raise_error(ArgumentError, "Author information (scholar_id or scholar_full_name) is required")
    end
  end
end
