require 'rails_helper'

RSpec.describe Domain, type: :model do
  subject(:domain) { build(:domain) }

  describe 'associations' do
    it { should have_one_attached(:logo) }
    it { should have_one_attached(:art_work) }
    it { should have_many(:domain_assignments).dependent(:destroy) }
  end

  describe 'class methods' do
    describe '.find_by_host' do
      let!(:domain1) { create(:domain, host: 'example.com') }
      let!(:domain2) { create(:domain, host: 'test.com') }

      it 'finds domain by host' do
        expect(Domain.find_by_host('example.com')).to eq(domain1)
        expect(Domain.find_by_host('test.com')).to eq(domain2)
      end

      it 'returns nil for non-existent host' do
        expect(Domain.find_by_host('nonexistent.com')).to be_nil
      end
    end
  end

  describe 'instance methods' do
    let(:domain) { create(:domain) }

    describe '#assigned_items' do
      it 'returns domain assignments with includes' do
        expect(domain.assigned_items).to be_a(ActiveRecord::Relation)
      end
    end

    describe '#has_custom_css?' do
      it 'returns true when custom_css is present' do
        domain.custom_css = 'body { color: red; }'
        expect(domain.has_custom_css?).to be true
      end

      it 'returns false when custom_css is blank' do
        domain.custom_css = ''
        expect(domain.has_custom_css?).to be false
      end
    end
  end
end
