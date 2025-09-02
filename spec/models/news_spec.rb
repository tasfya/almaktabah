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
    it { should validate_presence_of(:published_at) }
  end

  describe 'included modules' do
    it 'includes Publishable' do
      expect(News.included_modules).to include(Publishable)
    end

    it 'includes DomainAssignable' do
      expect(News.included_modules).to include(DomainAssignable)
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
        expected_attributes = [ "created_at", "id", "published_at", "title", "description", "updated_at" ]
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
