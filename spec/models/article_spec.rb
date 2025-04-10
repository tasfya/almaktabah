require "rails_helper"

RSpec.describe Article, type: :model do
  context "factories" do
    it "has a valid factory" do
      expect(build(:article)).to be_valid
    end
  end
end
