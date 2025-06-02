require 'rails_helper'

RSpec.describe ApiToken, type: :model do
  describe "validations" do
    let(:user) { create(:user) }
    let(:token) { build(:api_token, user: user) }

    it "requires a token" do
      token.token = nil
      expect(token).not_to be_valid
      expect(token.errors[:token]).to include("can't be blank")
    end

    it "requires a purpose" do
      token.purpose = nil
      expect(token).not_to be_valid
      expect(token.errors[:purpose]).to include("can't be blank")
    end

    it "requires a user" do
      token.user = nil
      expect(token).not_to be_valid
      expect(token.errors[:user]).to include("can't be blank")
    end

    it "requires a unique token" do
      token.save!
      duplicate = build(:api_token, token: token.token)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token]).to include("has already been taken")
    end
  end

  describe "associations" do
    let(:user) { create(:user) }
    let(:token) { create(:api_token, user: user) }

    it "belongs to a user" do
      expect(token.user).to eq(user)
    end
  end
end
