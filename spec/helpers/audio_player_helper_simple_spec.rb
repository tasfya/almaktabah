require 'rails_helper'

RSpec.describe AudioPlayerHelper, type: :helper do
  describe "#play_button" do
    it "has a play_button method" do
      expect(helper).to respond_to(:play_button)
    end
  end
end
