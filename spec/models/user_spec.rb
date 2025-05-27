require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'admin functionality' do
    it 'defaults admin to false for new users' do
      user = User.new
      expect(user.admin).to be_falsey
    end

    describe '#admin?' do
      it 'returns true when user is an admin' do
        user = build(:user, admin: true)
        expect(user.admin?).to be true
      end

      it 'returns false when user is not an admin' do
        user = build(:user, admin: false)
        expect(user.admin?).to be false
      end
    end

    describe '.admins scope' do
      before do
        create(:user, email: 'regular@example.com', admin: false)
        create(:user, email: 'admin@example.com', admin: true)
      end

      it 'returns only admin users' do
        expect(User.admins.count).to eq(1)
        expect(User.admins.first.email).to eq('admin@example.com')
      end
    end
  end
end
