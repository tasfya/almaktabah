require 'rails_helper'

RSpec.describe ActionLog, type: :model do
  subject(:action_log) { build(:action_log) }

  describe 'associations' do
    it { should belong_to(:actionable) }
  end
end
