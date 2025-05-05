require 'rails_helper'

RSpec.describe JsonWebToken do
  describe '.encode' do
    let(:payload) { { user_id: 1 } }
    let(:token) { described_class.encode(payload) }

    it 'encodes a payload into a JWT token' do
      expect(token).to be_a(String)
    end

    it 'includes expiration time in the payload' do
      decoded_payload = JWT.decode(token, described_class::SECRET_KEY)[0]
      expect(decoded_payload).to include('exp')
    end

    context 'when custom expiration is provided' do
      let(:expiration) { 1.hour.from_now }
      let(:token) { described_class.encode(payload, expiration) }

      it 'sets the custom expiration time' do
        decoded_payload = JWT.decode(token, described_class::SECRET_KEY)[0]
        expect(decoded_payload['exp']).to eq(expiration.to_i)
      end
    end
  end

  describe '.decode' do
    let(:user_id) { 1 }
    let(:payload) { { user_id: user_id } }
    let(:token) { described_class.encode(payload) }

    it 'decodes a JWT token and returns a hash with indifferent access' do
      decoded = described_class.decode(token)
      expect(decoded).to be_a(HashWithIndifferentAccess)
      expect(decoded[:user_id]).to eq(user_id)
    end

    context 'when token is invalid' do
      it 'returns nil' do
        result = described_class.decode('invalid_token')
        expect(result).to be_nil
      end
    end

    context 'when token is nil' do
      it 'returns nil' do
        result = described_class.decode(nil)
        expect(result).to be_nil
      end
    end
  end
end
