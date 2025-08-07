require 'rails_helper'

RSpec.describe Fatwa, type: :model do
  subject(:fatwa) { build(:fatwa) }

  describe 'associations' do
    it { should have_rich_text(:question) }
    it { should have_rich_text(:answer) }
  end

  describe 'included modules' do
    it 'includes Publishable' do
      expect(Fatwa.included_modules).to include(Publishable)
    end

    it 'includes DomainAssignable' do
      expect(Fatwa.included_modules).to include(DomainAssignable)
    end
  end

  describe 'scopes and ransack' do
    describe '.ransackable_attributes' do
      it 'includes expected attributes' do
        expected_attributes = [ "category", "description", "created_at", "id", "published", "published_at", "scholar_id", "title", "updated_at" ]
        expect(Fatwa.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'includes expected associations' do
        expected_associations = [ "scholar" ]
        expect(Fatwa.ransackable_associations).to match_array(expected_associations)
      end
    end
  end

  describe 'domain assignment' do
    let!(:domain) { create(:domain) }
    let!(:test_fatwa) { create(:fatwa, :without_domain) }

    before do
      test_fatwa.assign_to(domain)
    end

    it 'assigns fatwa to domain' do
      expect(test_fatwa.domains).to include(domain)
    end

    it 'checks if fatwa is assigned to domain' do
      expect(test_fatwa.assigned_to?(domain)).to be_truthy
    end

    it 'unassigns fatwa from domain' do
      test_fatwa.unassign_from(domain)
      expect(test_fatwa.domains).not_to include(domain)
    end

    it 'returns assigned domains' do
      expect(test_fatwa.assigned_domains).to include(domain)
    end
  end
end
