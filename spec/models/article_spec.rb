require 'rails_helper'

RSpec.describe Article, type: :model do
  subject(:article) { build(:article) }

  describe 'associations' do
    it { should belong_to(:author).class_name('Scholar') }
  end

  describe 'included modules' do
    it 'includes Publishable' do
      expect(Article.included_modules).to include(Publishable)
    end

    it 'includes DomainAssignable' do
      expect(Article.included_modules).to include(DomainAssignable)
    end
  end

  describe 'scopes and ransack' do
    describe '.ransackable_attributes' do
      it 'includes expected attributes' do
        expected_attributes = [ "id", "title", "author_id", "published", "published_at", "created_at", "updated_at" ]
        expect(Article.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'includes expected associations' do
        expected_associations = [ "author" ]
        expect(Article.ransackable_associations).to match_array(expected_associations)
      end
    end
  end

  describe 'domain assignment' do
    let!(:domain) { create(:domain) }
    let!(:test_article) { create(:article) }

    before do
      test_article.assign_to(domain)
    end

    it 'assigns article to domain' do
      expect(test_article.domains).to include(domain)
    end

    it 'checks if article is assigned to domain' do
      expect(test_article.assigned_to?(domain)).to be_truthy
    end

    it 'unassigns article from domain' do
      test_article.unassign_from(domain)
      expect(test_article.domains).not_to include(domain)
    end

    it 'returns assigned domains' do
      expect(test_article.assigned_domains).to include(domain)
    end
  end
end
