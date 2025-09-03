require 'rails_helper'

RSpec.describe News, type: :model do
  subject(:news) { build(:news) }

  describe 'associations' do
    it { should have_one_attached(:thumbnail) }
    it { should have_rich_text(:content) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:content) }
  end

  describe 'included modules' do
    it 'includes Publishable' do
      expect(News.included_modules).to include(Publishable)
    end

    it 'includes DomainAssignable' do
      expect(News.included_modules).to include(DomainAssignable)
    end

    it 'includes Sluggable' do
      expect(News.included_modules).to include(Sluggable)
    end
  end

  describe 'slug functionality' do
    let(:news_item) { create(:news, title: 'أخبار المسجد الجديد') }

    it 'generates a slug from the title' do
      expect(news_item.slug).to eq('أخبار-المسجد-الجديد')
    end

    it 'can be found by slug' do
      expect(News.friendly.find(news_item.slug)).to eq(news_item)
    end

    it 'maintains slug history when title changes' do
      old_slug = news_item.slug
      news_item.update!(title: 'عنوان جديد للخبر')

      expect(news_item.slug).to eq('عنوان-جديد-للخبر')
      expect(News.friendly.find(old_slug)).to eq(news_item)
    end

    it 'works with English titles' do
      english_news = create(:news, title: 'Important News Update')
      expect(english_news.slug).to eq('important-news-update')
    end
  end

  describe 'scopes' do
    describe '.recent' do
      let!(:old_news) { create(:news, published_at: 2.weeks.ago) }
      let!(:new_news) { create(:news, published_at: 1.week.ago) }

      it 'orders news by published_at descending' do
        expect(News.recent).to eq([ new_news, old_news ])
      end
    end
  end

  describe 'scopes and ransack' do
    describe '.ransackable_attributes' do
      it 'includes expected attributes' do
        expected_attributes = [ "created_at", "id", "published_at", "title", "description", "slug", "updated_at" ]
        expect(News.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'includes expected associations' do
        expected_associations = []
        expect(News.ransackable_associations).to match_array(expected_associations)
      end
    end
  end

  describe 'domain assignment' do
    let!(:domain) { create(:domain) }
    let!(:test_news) { create(:news, :without_domain) }

    before do
      test_news.assign_to(domain)
    end

    it 'assigns news to domain' do
      expect(test_news.domains).to include(domain)
    end

    it 'checks if news is assigned to domain' do
      expect(test_news.assigned_to?(domain)).to be_truthy
    end

    it 'unassigns news from domain' do
      test_news.unassign_from(domain)
      expect(test_news.domains).not_to include(domain)
    end

    it 'returns assigned domains' do
      expect(test_news.assigned_domains).to include(domain)
    end
  end
end
