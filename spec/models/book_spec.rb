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

  describe 'slug functionality' do
    context 'when title is in Arabic' do
      it 'generates slug from Arabic title' do
        arabic_book = create(:book, title: 'كتاب التوحيد')
        expect(arabic_book.slug).to eq('كتاب-التوحيد')
      end

      it 'can be found using friendly finder' do
        arabic_book = create(:book, title: 'الأسماء والصفات')
        found_book = Book.friendly.find('الأسماء-والصفات')
        expect(found_book).to eq(arabic_book)
      end
    end

    context 'when title is in English' do
      it 'generates slug from English title' do
        english_book = create(:book, title: 'The Book of Monotheism')
        expect(english_book.slug).to eq('the-book-of-monotheism')
      end

      it 'can be found using friendly finder' do
        english_book = create(:book, title: 'Islamic Theology')
        found_book = Book.friendly.find('islamic-theology')
        expect(found_book).to eq(english_book)
      end
    end

    context 'slug history' do
      it 'maintains old slug when title changes' do
        book = create(:book, title: 'كتاب الصلاة')
        old_slug = book.slug

        book.update(title: 'فقه الصلاة')
        book.reload

        expect(book.slug).to eq('فقه-الصلاة')
        expect(Book.friendly.find(old_slug)).to eq(book)
        expect(Book.friendly.find('فقه-الصلاة')).to eq(book)
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
