require 'rails_helper'

RSpec.describe Book, type: :model do
  subject(:book) { build(:book) }

  describe 'associations' do
    it { should belong_to(:author).class_name('Scholar') }
    it { should have_one_attached(:file) }
    it { should have_one_attached(:cover_image) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:author) }
    it { should validate_uniqueness_of(:title) }
  end

  describe 'scopes and ransack' do
    describe '.ransackable_attributes' do
      it 'includes expected attributes' do
        expected_attributes = [ "author_id", "category", "created_at", "description", "downloads", "id", "published", "published_at", "title", "updated_at" ]
        expect(Book.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'includes expected associations' do
        expected_associations = [ "author" ]
        expect(Book.ransackable_associations).to match_array(expected_associations)
      end
    end
  end

  describe 'domain assignment' do
    let(:domain) { create(:domain) }
    let(:test_book) { create(:book, :without_domain) }

    it 'assigns book to domain' do
      test_book.assign_to(domain)
      test_book.reload
      expect(test_book.domains).to include(domain)
    end

    it 'checks if book is assigned to domain' do
      test_book.assign_to(domain)
      expect(test_book.assigned_to?(domain)).to be_truthy
    end

    it 'unassigns book from domain' do
      test_book.assign_to(domain)
      test_book.unassign_from(domain)
      test_book.reload
      expect(test_book.domains).not_to include(domain)
    end

    it 'returns assigned domains' do
      test_book.assign_to(domain)
      test_book.reload
      expect(test_book.assigned_domains).to include(domain)
    end
  end
end
