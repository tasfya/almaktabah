require 'rails_helper'

RSpec.describe DomainAssignment, type: :model do
  subject(:domain_assignment) { build(:domain_assignment) }

  describe 'associations' do
    it { should belong_to(:domain) }
    it { should belong_to(:assignable) }
  end

  describe 'functionality' do
    let(:domain) { create(:domain) }
    let(:book) { create(:book) }

    it 'creates assignment between domain and assignable' do
      assignment = DomainAssignment.create!(domain: domain, assignable: book)

      expect(assignment.domain).to eq(domain)
      expect(assignment.assignable).to eq(book)
      expect(assignment.assignable_type).to eq('Book')
      expect(assignment.assignable_id).to eq(book.id)
    end
  end
end
