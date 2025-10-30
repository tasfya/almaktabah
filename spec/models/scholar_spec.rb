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
