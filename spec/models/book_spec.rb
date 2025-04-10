require "rails_helper"

RSpec.describe Book, type: :model do
  context "factories" do
    it "has a valid factory" do
      expect(build(:book)).to be_valid
    end
  end
end
