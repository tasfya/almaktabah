require 'rails_helper'

RSpec.describe Lecture, type: :model do
  describe "domain assignment" do
    let(:domain) { create(:domain) }
    let(:lecture) { create(:lecture) }

    it "assigns lecture to domain" do
      expect {
        lecture.assign_to(domain)
      }.to change { lecture.domain_assignments.count }.by(1)
      expect(lecture.domains).to include(domain)
    end

    it "checks if lecture is assigned to domain" do
      lecture.assign_to(domain)
      expect(lecture.assigned_to?(domain)).to be true
    end

    it "unassigns lecture from domain" do
      lecture.assign_to(domain)
      expect {
        lecture.unassign_from(domain)
      }.to change { lecture.domain_assignments.count }.by(-1)
    end

    it "returns assigned domains" do
      lecture.assign_to(domain)
      expect(lecture.assigned_domains).to include(domain)
    end
  end
end
