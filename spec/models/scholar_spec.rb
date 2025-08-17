require 'rails_helper'

RSpec.describe Scholar, type: :model do
  subject(:scholar) { build(:scholar) }

  describe 'associations' do
    it { should have_rich_text(:bio) }
  end

  describe 'included modules' do
    it 'includes Publishable' do
      expect(Scholar.included_modules).to include(Publishable)
    end
  end

  describe 'methods' do
    describe '#name' do
      context 'when both first and last names are present' do
        let(:scholar) { build(:scholar, first_name: 'Ahmed', last_name: 'Al-Scholar') }

        it 'returns full name' do
          expect(scholar.name).to eq('Ahmed Al-Scholar')
        end
      end

      context 'when only first name is present' do
        let(:scholar) { build(:scholar, first_name: 'Ahmed', last_name: nil) }

        it 'returns first name only' do
          expect(scholar.name).to eq('Ahmed')
        end
      end

      context 'when only last name is present' do
        let(:scholar) { build(:scholar, first_name: nil, last_name: 'Al-Scholar') }

        it 'returns last name only' do
          expect(scholar.name).to eq('Al-Scholar')
        end
      end
    end
  end

  describe 'scopes and ransack' do
    describe '.ransackable_attributes' do
      it 'includes expected attributes' do
        expected_attributes = [ "created_at", "first_name", "id", "last_name", "updated_at" ]
        expect(Scholar.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'includes expected associations' do
        expected_associations = []
        expect(Scholar.ransackable_associations).to match_array(expected_associations)
      end
    end
  end
end
